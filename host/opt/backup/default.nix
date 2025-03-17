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

    deleteOlderThan = mkOption {default = "2 months ago";};

    snapshotOnCalendar = mkOption {default = "daily";};
    backupOnCalendar = mkOption {default = "*-*-01 06:00:00";};
  };

  config = {
    nixpkgs.overlays = [
      (final: _: {
        my-snapshot = final.writeNushellApplication {
          name = "snapshot.nu";
          runtimeInputs = with final; [util-linux btrfs-progs];
          text = builtins.readFile ./btrfs-snapshot.nu;
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
            _lock() { ${lib.getExe pkgs.flock} -"$1" "$LOCKFD"; }
            _no_more_locking() { _lock u ; _lock xn && rm -f "$LOCKFILE"; }
            _prepare_locking() { eval "exec $LOCKFD>\"$LOCKFILE\""; trap _no_more_locking EXIT; }
            _prepare_locking

            _lock xn || exit 1
            ${lib.getExe' pkgs.systemd "systemd-inhibit"} \
              --no-ask-password --what="sleep:idle" --mode="block" \
              --who="btrfs-snapshots.service" --why="Snapshotting ${cfg.localDrive} to ${cfg.localSnapshotDrive}" \
              ${lib.getExe pkgs.my-snapshot} \
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

        backup = {
          description = "Incremental backup to the cloud";
          after = ["network-online.target" "btrfs-snapshots.service"];
          requires = ["network-online.target" "btrfs-snapshots.service"];

          script = ''
            cd / || exit 1
            LOCKFILE="/var/run/backupdisk"
            LOCKFD=99
            _lock() { ${lib.getExe pkgs.flock} -"$1" "$LOCKFD"; }
            _no_more_locking() { _lock u ; _lock xn && rm -f "$LOCKFILE"; }
            _prepare_locking() { eval "exec $LOCKFD>\"$LOCKFILE\""; trap _no_more_locking EXIT; }
            _prepare_locking

            _lock xn || exit 1
            ${lib.getExe pkgs.my-backup} >/var/log/backupdisk 2>/var/log/backupdisk.err
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
