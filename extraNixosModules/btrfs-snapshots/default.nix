# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib.strings) escapeShellArg;
  cfg = config.my.backup;

  my-snapshot = pkgs.writeNushellApplication {
    name = "snapshot.nu";
    runtimeInputs = with pkgs; [util-linux btrfs-progs];
    text = builtins.readFile ./btrfs-snapshot.nu;
  };
in {
  options.my.backup = {
    localDrive = mkOption {default = "/dev/disk/by-label/nixos";};
    localSnapshotDrive = mkOption {default = "/dev/disk/by-label/mass";};
    snapshotPrefix = mkOption {default = "safe";};
    deleteOlderThan = mkOption {default = "2 months ago";};
    snapshotOnCalendar = mkOption {default = "daily";};
  };

  config.systemd = {
    timers.btrfs-snapshots = {
      description = "Daily incremental BtrFS snapshots";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = cfg.snapshotOnCalendar;
        Persistent = true;
        RandomizedDelaySec = 600;
      };
    };

    services.btrfs-snapshots = {
      description = "Create incremental BtrFS snapshots";
      after = ["network-online.target"];
      requires = ["network-online.target"];

      script = ''
        cd / || exit 1
        LOCKFILE="/var/run/backupdisk"
        LOCKFD=99
        _lock() { ${lib.getExe pkgs.flock} -"$1" "$LOCKFD"; }
        _no_more_locking() { _lock u ; _lock xn && rm -f "$LOCKFILE"; }
        _prepare_locking() { eval "exec $LOCKFD>\"$LOCKFILE\""; trap _no_more_locking EXIT; }
        _prepare_locking

        _lock xn || exit 1
        ${lib.getExe' pkgs.systemd "systemd-inhibit"} \
          --no-ask-password --what="sleep:idle" --mode="block" \
          --who="btrfs-snapshots.service" --why="Snapshotting ${cfg.localDrive} to ${cfg.localSnapshotDrive}" \
          ${lib.getExe my-snapshot} \
          ${escapeShellArg cfg.localDrive} \
          ${escapeShellArg cfg.localSnapshotDrive} \
          --delete-older-than ${escapeShellArg cfg.deleteOlderThan} \
          --snapshot-prefix ${escapeShellArg cfg.snapshotPrefix} \
          |& tee -a /var/log/snapshotdisk
      '';
      path = [pkgs.nix];
      serviceConfig = {
        Type = "simple";
        RestartSec = "5min";
      };
    };
  };
}
