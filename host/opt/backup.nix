{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib.strings) escapeShellArg;
  cfg = config.my.backup;
in {
  options.my.backup = {
    bucket = mkOption {default = "";};

    localDrive = mkOption {default = "/dev/disk/by-label/nixos";};
    localSnapshotDrive = mkOption {default = "/dev/disk/by-label/mass";};
    snapshotPrefix = mkOption {default = "safe";};

    deleteOlderThan = mkOption {default = "now - 2 months";};

    snapshotOnCalendar = mkOption {default = "daily";};
    backupOnCalendar = mkOption {default = "*-*-01 06:00:00";};
  };

  config = {
    nixpkgs.overlays = [
      (final: _: {
        my-snapshot = final.writeShellApplication {
          name = "snapshot.bash";
          runtimeInputs = with final; [util-linux gnugrep btrfs-progs rclone mktemp coreutils-full findutils gawk];
          text = ''
            shopt -s nullglob globstar

            if [ "$(id -u)" != 0 ]; then
              echo "Error: Must run ''${0} as root" >&2
              exit 1
            fi

            function cleanup() {
              [[ -f "$NOSLEEP" ]] && (rm "$NOSLEEP" || :)
              [[ -f /var/run/backupdisk.pid ]] && (rm /var/run/backupdisk.pid || :)
              if [[ -d "$MNT" ]] ; then
                [[ -d "$TMPDIR" ]] && btrfs subvolume delete "$TMPDIR"
                [[ -d "$NTMPDIR" ]] && btrfs subvolume delete "$NTMPDIR"
                umount "$MNT/nix" || :
                umount "$MNT/backup" || :
                rmdir "$MNT/nix" "$MNT/backup" "$MNT"
              fi
            }
            trap cleanup EXIT
            echo "$$" > /var/run/backupdisk.pid

            NOSLEEP="$(mktemp --tmpdir=/var/run/prevent-sleep.d)"
            MNT="$(mktemp -d)"
            TS="$(date +%Y-%m-%d)"
            CUTOFF_DATE="$(date -d ${escapeShellArg cfg.deleteOlderThan} +%s)"

            mkdir "$MNT/nix" "$MNT/backup"

            mount ${escapeShellArg cfg.localDrive} "$MNT/nix"
            mount ${escapeShellArg cfg.localSnapshotDrive} "$MNT/backup"

            SNAPSHOT_DIR="$MNT/backup/"${escapeShellArg cfg.snapshotPrefix}
            TMPDIR="$(mktemp -d --tmpdir="$MNT/backup")"
            NTMPDIR="$(mktemp -d --tmpdir="$MNT/nix")"
            mkdir -p "$MNT/nix/safe" "$SNAPSHOT_DIR"

            for vol in "$MNT/nix/safe/"* ; do
              [[ "$vol" == "$MNT/nix/safe/*" ]] && break
              NAME="$(basename "$vol")"
              [[ -e "$SNAPSHOT_DIR/$NAME.$TS" ]] && continue

              [[ -d "$NTMPDIR/$NAME" ]] && (btrfs subvolume delete "$NTMPDIR/$NAME" || :)
              [[ -e "''${NTMPDIR:?}/$NAME" ]] && rm -rf "''${NTMPDIR:?}/$NAME"
              btrfs subvolume snapshot -r "$vol" "$NTMPDIR/$NAME"

              if [[ -d "$SNAPSHOT_DIR/$NAME" ]]; then
                btrfs subvolume delete "$MNT/backup/safe/$NAME"
              fi

              btrfs send "$NTMPDIR/$NAME" | btrfs receive -m "$MNT/backup" "$TMPDIR"
              btrfs subvolume snapshot -r "$TMPDIR/$NAME" "$SNAPSHOT_DIR/$NAME"
              btrfs subvolume snapshot -r "$TMPDIR/$NAME" "$SNAPSHOT_DIR/$NAME.$TS"
              btrfs subvolume delete "$NTMPDIR/$NAME"
              btrfs subvolume delete "$TMPDIR/$NAME"
            done

            rmdir "$NTMPDIR"
            rmdir "$TMPDIR"
            umount "$MNT/nix"

            for snap in "$SNAPSHOT_DIR/"*; do
              [[ "$snap" == "$SNAPSHOT_DIR/*" ]] && break
              [[ -d "$snap" ]] || continue
              TS="$(basename "$snap")"
              [[ "$TS" =~ ^([^.]+)\.[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || continue
              MTIME="$(awk -F. '{print $2}' <<< "$TS" | xargs -n1 date +%s -d | head -n1)"
              (( MTIME <= CUTOFF_DATE )) && btrfs subvolume delete "$snap"
            done

            umount "$MNT/backup"
            rmdir "$MNT/backup" "$MNT/nix" "$MNT"
          '';
        };

        my-backup = final.writeShellApplication {
          name = "backup.bash";
          runtimeInputs = with final; [util-linux gnugrep rclone mktemp];
          text = ''
            shopt -s nullglob globstar

            if [ "$(id -u)" != 0 ]; then
              echo "Error: Must run ''${0} as root" >&2
              exit 1
            fi

            function cleanup() {
              [[ -f "$NOSLEEP" ]] && (rm "$NOSLEEP" || :)
              [[ -f /var/run/backupdisk.pid ]] && (rm /var/run/backupdisk.pid || :)
            }
            trap cleanup EXIT
            echo "$$" > /var/run/backupdisk.pid

            NOSLEEP="$(mktemp --tmpdir=/var/run/prevent-sleep.d)"
            MNT="$(mktemp -d)"
            BUCKET=${escapeShellArg cfg.bucket}
            DATE="$(date '+%Y-%m-%d-%H:%M:%S')"
            SNAPSHOT_DIR="$MNT/"${escapeShellArg cfg.snapshotPrefix}

            mount ${escapeShellArg cfg.localSnapshotDrive} "$MNT"
            mkdir -p "$MNT/safe"

            for snap in "$SNAPSHOT_DIR/"*; do
              [[ "$snap" == "$SNAPSHOT_DIR/*" ]] && break
              [[ -d "$snap" ]] || continue
              NAME="$(basename "$snap")"
              grep --quiet "\\." <<< "$NAME" && continue

              rclone --config ${config.sops.templates."rclone.conf".path}  \
                sync "$snap" "backblaze:$BUCKET/LATEST/$NAME" --links -P --backup-dir \
                "backblaze:$BUCKET/$DATE/$NAME" || :
            done

            umount "$MNT"
            rmdir "$MNT"
          '';
        };

        my-snapshot-cleanup = final.writeShellApplication {
          name = "snapshotcleanup.bash";
          runtimeInputs = with final; [util-linux mktemp findutils];
          text = ''
            shopt -s nullglob globstar

            if [ "$(id -u)" != 0 ]; then
              echo "Error: Must run ''${0} as root" >&2
              exit 1
            fi

            function cleanup() {
              [[ -f "$NOSLEEP" ]] && (rm "$NOSLEEP" || :)
              if [[ -d "$MNT" ]] ; then
                umount "$MNT" || :
                rmdir "$MNT"
              fi
            }
            trap cleanup EXIT

            NOSLEEP="$(mktemp --tmpdir=/var/run/prevent-sleep.d)"
            MNT="$(mktemp -d)"

            mount ${escapeShellArg cfg.localSnapshotDrive} "$MNT"
            find "$MNT" -mindepth 1 -maxdepth 1 -type d -name "tmp.*" -execdir rm -rf '{}' '+'
          '';
        };
      })
    ];

    sops = {
      secrets = {
        backblaze_key_id = {};
        backblaze_application_key = {};
      };
      templates."rclone.conf".content = let
        inherit (config.sops.placeholder) backblaze_key_id backblaze_application_key;
      in
        /*
        ini
        */
        ''
          [backblaze]
          type = b2
          account = ${backblaze_key_id}
          key = ${backblaze_application_key}
          hard_delete = true
        '';
    };

    systemd = {
      timers = {
        btrfs-snapshots = {
          description = "Daily incremental BtrFS snapshots";
          wantedBy = ["timers.target"];
          timerConfig = {
            OnCalendar = cfg.snapshotOnCalendar;
            Persistent = true;
            RandomizedDelaySec = 600;
          };
        };

        btrfs-cleanup = {
          description = "Cleanup from btrfs-snapshots.timer";
          wantedBy = ["timers.target"];
          timerConfig = {
            OnCalendar = "Mon,Wed,Fri *-*-* 00:00:00";
            Persistent = true;
            RandomizedDelaySec = 600;
          };
        };

        backup = {
          description = "Monthly incremental backups to the cloud";
          wantedBy = ["timers.target"];
          timerConfig = {
            OnCalendar = cfg.backupOnCalendar;
            Persistent = true;
            RandomizedDelaySec = 600;
          };
        };
      };

      services = {
        btrfs-snapshots = {
          description = "Create incremental BtrFS snapshots";
          after = ["network-online.target"];
          requires = ["network-online.target"];

          script = ''
            cd / || exit 1
            LOCKFILE="/var/run/backupdisk"
            LOCKFD=99
            _lock() { ${pkgs.flock}/bin/flock -"$1" "$LOCKFD"; }
            _no_more_locking() { _lock u ; _lock xn && rm -f "$LOCKFILE"; }
            _prepare_locking() { eval "exec $LOCKFD>\"$LOCKFILE\""; trap _no_more_locking EXIT; }
            _prepare_locking

            _lock xn || exit 1
            ${pkgs.my-snapshot}/bin/snapshot.bash >/var/log/snapshotdisk 2>/var/log/snapshotdisk.err
          '';
          path = [pkgs.nix];
          serviceConfig = {
            Type = "simple";
            RestartSec = "5min";
          };
        };

        btrfs-cleanup = {
          description = "Cleanup any lingering temporary data from btrfs-snapshots.service";
          after = ["btrfs-snapshots.service"];

          script = ''
            cd / || exit 1
            ${pkgs.my-snapshot-cleanup}/bin/snapshotcleanup.bash >/var/log/snapshotcleanup 2>/var/log/snapshotcleanup.err
          '';
        };

        backup = {
          description = "Incremental backup to the cloud";
          after = ["network-online.target" "btrfs-snapshots.service"];
          requires = ["network-online.target" "btrfs-snapshots.service"];

          script = ''
            cd / || exit 1
            LOCKFILE="/var/run/backupdisk"
            LOCKFD=99
            _lock() { ${pkgs.flock}/bin/flock -"$1" "$LOCKFD"; }
            _no_more_locking() { _lock u ; _lock xn && rm -f "$LOCKFILE"; }
            _prepare_locking() { eval "exec $LOCKFD>\"$LOCKFILE\""; trap _no_more_locking EXIT; }
            _prepare_locking

            _lock xn || exit 1
            ${pkgs.my-backup}/bin/backup.bash >/var/log/backupdisk 2>/var/log/backupdisk.err
          '';
          path = [pkgs.nix];
          serviceConfig = {
            Type = "simple";
            RestartSec = "5min";
          };
        };
      };
    };
  };
}
