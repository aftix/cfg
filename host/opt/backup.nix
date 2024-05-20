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
          runtimeInputs = with final; [util-linux gnugrep btrfs-progs rclone mktemp];
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
            TS="$(date +%Y-%m-%d)"
            CUTOFF_DATE="$(${pkgs.coreutils}/bin/date -d ${escapeShellArg cfg.deleteOlderThan} +%s)"

            mkdir "$MNT/nix" "$MNT/backup"

            mount ${escapeShellArg cfg.localDrive} "$MNT/nix"
            mount ${escapeShellArg cfg.localSnapshotDrive} "$MNT/backup"

            SNAPSHOT_DIR="$MNT/backup/"${escapeShellArg cfg.snapshotPrefix}
            mkdir -p "$MNT/nix/safe" "$SNAPSHOT_DIR" "$MNT/nix/tmp" "$MNT/backup/tmp"

            for vol in "$MNT/nix/safe/"* ; do
              [[ "$vol" == "$MNT/nix/safe/*" ]] && break
              NAME="$(basename "$vol")"
              [[ -e "$SNAPSHOT_DIR/$NAME.$TS" ]] && continue

              [[ -d "$MNT/nix/tmp/$NAME" ]] && (btrfs subvolume delete "$MNT/nix/tmp/$NAME" || :)
              [[ -e "$MNT/nix/tmp/$NAME" ]] && rm -rf "$MNT/nix/tmp/$NAME"
              btrfs subvolume snapshot -r "$vol" "$MNT/nix/tmp/$NAME"

              if [[ -d "$SNAPSHOT_DIR/$NAME" ]]; then
                btrfs subvolume delete "$MNT/backup/safe/$NAME"
              fi

              btrfs send "$MNT/nix/tmp/$NAME" | btrfs receive -m "$MNT/backup" "$MNT/backup/tmp"
              btrfs subvolume snapshot -r "$MNT/backup/tmp/$NAME" "$SNAPSHOT_DIR/$NAME"
              btrfs subvolume snapshot -r "$MNT/backup/tmp/$NAME" "$SNAPSHOT_DIR/$NAME.$TS"
              btrfs subvolume delete "$MNT/nix/tmp/$NAME"
            done

            rmdir "$MNT/nix/tmp"
            umount "$MNT/nix"

            for snap in "$SNAPSHOT_DIR/"*; do
              [[ "$snap" == "$SNAPSHOT_DIR/*" ]] && break
              [[ -d "$snap" ]] || continue
              MTIME="$(date -r "$snap" +%s)"
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
      })
    ];

    sops = {
      secrets = {
        backblaze_key_id = {};
        backblaze_application_key = {};
      };
      templates."rclone.conf".content = let
        inherit (config.sops.placeholder) backblaze_key_id backblaze_application_key;
      in ''
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
            ${pkgs.daemonize}/bin/daemonize -l /var/run/backupdisk -e /var/log/snapshotdisk.err -o /var/log/snapshotdisk ${pkgs.my-snapshot}/bin/snapshot.bash
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
            ${pkgs.daemonize}/bin/daemonize -l /var/run/backupdisk -e /var/log/backupdisk.err -o /var/log/backupdisk ${pkgs.my-backup}/bin/backup.bash
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
