# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2

# Send btrfs snapshot from one disk to another, with timestamp and cleanup of old snapshots
# This script expects to be run with systemd-inhibit and with a lockfile held
let timestamp = date now
let timestampFmt = "%Y-%m-%d"

use std/log

def main [
  localDrive: string
  snapshotDrive: string
  # Passed to the `date` command
  --delete-older-than: string
  --snapshot-prefix: string
  # Top-level subvolume tree under root which to snapshot
  --safe-subvolume: string
] {
  if (id -u | into int) != 0 {
    log critical "This script must be run as root"
    error make { msg: $"Must run ($env.CURRENT_FILE) as root" }
  }

  let deleteOlderThan = try {
    $timestamp - (if $delete_older_than == null { "8wk" } else { $delete_older_than } | into duration)
  } catch {
    error make { msg: $"Failed to parse deleteOlderThan string ($delete_older_than) as a duration" }
  }

  let safeSubvol = if $safe_subvolume == null { "safe" } else { $safe_subvolume }
  let snapshotPrefix = if $snapshot_prefix == null { "safe" } else { $snapshot_prefix }

  if not ($localDrive | path exists) {
    error make { msg: $"Path ($localDrive) does not exist" }
  }
  if not ($snapshotDrive | path exists) {
    error make { msg: $"Path ($localDrive) does not exist" }
  }

  log debug "Ensuring passed drives are BTRFS..."
  let blockDevices = (blkid | detect columns --no-headers)
  let localBlockDevice = ($blockDevices | where column0 == $"(realpath $localDrive):")
  let snapshotBlockDevice = ($blockDevices | where column0 == $"(realpath $snapshotDrive):")
  if ($localBlockDevice | is-empty) {
    error make { msg: $"Path ($localDrive) is not a block device" }
  }
  if ($snapshotBlockDevice | is-empty) {
    error make { msg: $"Path ($snapshotDrive) is not a block device" }
  }
  if ($localBlockDevice | get column5.0) != 'TYPE="btrfs"' {
    error make { msg: $"Local drive ($localDrive) is not a BTRFS filesystem"}
  }
  if ($snapshotBlockDevice | get column5.0) != 'TYPE="btrfs"' {
    error make { msg: $"Snapshot drive ($snapshotDrive) is not a BTRFS filesystem"}
  }

  let mountDir = mktemp -d -t
  let localMount = $mountDir | path join nixos-local
  let snapshotMount = $mountDir | path join nixos-snapshots
  mkdir $localMount $snapshotMount
  log info $"Created temporary directories nixos-local,nixos-snapshots for mounting under ($mountDir)"

  # Mount the disks
  mount -o subvolid=5 $localDrive $localMount
  mount -o subvolid=5 $snapshotDrive $snapshotMount
  log info $"Mounted local disk ($localDrive) and snapshot disk ($snapshotDrive)"

  log info "Beginning snapshotting..."

  try {
    snapshot $localMount $snapshotMount $safeSubvol $snapshotPrefix
  } catch { log error "Failed to snapshot" }

  try {
    cleanupOlderSnapshots $snapshotMount $snapshotPrefix $deleteOlderThan
  } catch { log error "Failed to cleanup older snapshots"}

  try {
    cleanupTemporaries $localMount $snapshotMount
  } catch { log error "Failed to cleanup lingering temporary subvolumes" }

  log info "Snapshotting complete"

  log info "Cleaning up..."

  umount $localMount
  umount $snapshotMount
  log info "Disks unmounted"
  
  rmdir $localMount $snapshotMount
  rmdir $mountDir
  log info $"Temporary mount directories at ($mountDir) removed"
}

def currentTimestamp [] {
  $timestamp | format date $timestampFmt
}

def snapshot [localMount: string, snapshotMount: string, safeSubvol: string, snapshotPrefix: string] {
  if (not ($localMount | path join $safeSubvol | path exists)) {
    log warning $"Subdirectory ($safeSubvol) does not exist on local disk"
    return
  }

  let localTmpDir = mktemp -d --tmpdir-path=($localMount)
  let snapshotTmpDir = mktemp -d --tmpdir-path=($snapshotMount)

  try {
    ls ($localMount | path join $safeSubvol) | where type == dir | get name | each {|$localSubvol|
      log info $"Snapshotting subvolume ($localSubvol)"

      let subvolName = ($localSubvol | path basename)
      let target = ($snapshotMount | path join $snapshotPrefix $"($subvolName).(currentTimestamp)")
      let targetLatest = ($snapshotMount | path join $snapshotPrefix $subvolName)
      let localSnapshot = ($localTmpDir | path join $"($subvolName).(currentTimestamp)")
      let tmpSnapshot = ($snapshotTmpDir | path join $"($subvolName).(currentTimestamp)")

      if ($target | path exists) {
        log info $"Snapshot ($target) already exists, skipping"
        return
      }

      try {
        # Snapshot to a temporary subvolume on the local disk to be atomic
        if ($localSnapshot | path exists) {
          if ($localSnapshot | path type) == "dir" {
            try { btrfs subvolume delete $localSnapshot }
          } else {
            rm --permanent $localSnapshot
          }
        }

        log debug $"Snapshotting ($localSubvol) to ($localSnapshot)"
        btrfs subvolume snapshot -r $localSubvol $localSnapshot

        log debug $"Sending snapshot ($localSnapshot) to ($snapshotMount) in directory ($snapshotTmpDir | path basename)"
        btrfs send $localSnapshot | btrfs receive ($snapshotTmpDir)

        log debug $"Adding snapshot to final location: ($target)"
        btrfs subvolume snapshot -r $tmpSnapshot $target

        # Update the latest snapshot to point to this one
        log debug $"Clearing latest snapshot for ($subvolName)"
        if ($targetLatest | path exists) {
          if ($targetLatest | path type) == "dir" {
            try { btrfs subvolume delete $targetLatest }
          } else {
            rm --permanent $targetLatest
          }
        }

        log debug $"Snapshotting latest ($subvolName) from ($target) to ($targetLatest)"
        btrfs subvolume snapshot -r $target $targetLatest
      } catch {
        log error $"Failed to snapshot ($localSubvol)"
      }

      log debug $"Deleting intermediate subvolumes ($localSnapshot) and ($tmpSnapshot)"
      try { btrfs subvolume delete $localSnapshot }
      try { btrfs subvolume delete $tmpSnapshot }
    }
  } catch {
    log error "Failed to snapshot the local disk"
  }

  log debug $"Deleting temporary snapshot locations ($localTmpDir) and ($snapshotTmpDir)"
  try { rmdir $localTmpDir $snapshotTmpDir }
}

def cleanupOlderSnapshots [snapshotMount: string, snapshotPrefix: string, deleteOlderThan: datetime] {
  log info $"Cleaning up snapshots from before ($deleteOlderThan | format date $timestampFmt)"

  ls ($snapshotMount | path join $snapshotPrefix) | where type == "dir" and name =~ '.+\.\d{4}-\d{2}-\d{2}' | get name | par-each {|$snapshot|
    log debug $"Checking ($snapshot)"
    try {
      let snapshotTimestamp = $snapshot | path basename | split row . | last | into datetime

      if $snapshotTimestamp >= $deleteOlderThan {
        log debug $"Ignoring snapshot ($snapshot)"
        return
      }

      log info $"Deleting old snapshot ($snapshot)"
      try { btrfs subvolume delete $snapshot } catch { log error $"Failed to delete snapshot ($snapshot)" }
    } catch {
      log error $"Failed to parse timestamp from ($snapshot)"
    }
  }

  log info "Old snapshots cleaned up"
}

def cleanupTemporaries [localMount: string, snapshotMount: string] {
  log info "Deleting any lingering temporary subvolumes"

  ls $localMount | where type == "dir" and name =~ '^tmp\.' | get name | par-each {|tmp|
    log debug $"Removing any subvolumes inside ($tmp)"
    ls $tmp | select name type | par-each {|x| if $x.type == "dir" { btrfs subvolume delete $x.name} else {rm --permanent $x.name}}
    log debug $"Removing ($tmp)"
    rm --permanent -rf $tmp
  }
  ls $snapshotMount | where type == "dir" and name =~ '^tmp\.' | get name | par-each {|tmp|
    log debug $"Removing any subvolumes inside ($tmp)"
    ls $tmp | select name type | par-each {|x| if $x.type == "dir" { btrfs subvolume delete $x.name} else {rm --permanent $x.name}}
    log debug $"Removing ($tmp)"
    rm --permanent -rf $tmp
  }

  log info "Temporary subvolumes deleted"
}
