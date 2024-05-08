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
      (_: _: {
        my-snapshot = pkgs.writeScriptBin "snapshot.bash" ''
          #!${pkgs.stdenv.shell}
          shopt -s nullglob globstar
          export PATH="${pkgs.util-linux}/bin:${pkgs.gnugrep}/bin:$PATH"
          export PATH="${pkgs.btrfs-progs}/bin:${pkgs.rclone}/bin:${pkgs.mktemp}/bin:$PATH"

          if [ "$(id -u)" != 0 ]; then
            echo "Error: Must run ''${0} as root" >&2
            exit 1
          fi

          MNT="$(mktemp -d)"
          PIDFILE="/var/run/backupdisk.pid"
          TS="$(date +%Y-%m-%d)"
          CUTOFF_DATE="$(date -d ${escapeShellArg cfg.deleteOlderThan} +%s)"

          touch "$PIDFILE"
          exec 4<"$PIDFILE"
          flock 4

          echo "$$" > "$PIDFILE"

          mkdir "$MNT/nix" "$MNT/backup"

          mount ${escapeShellArg cfg.localDrive} "$MNT/nix"
          mount ${escapeShellArg cfg.localSnapshotDrive} "$MNT/backup"

          SNAPSHOT_DIR="$MNT/backup/"${escapeShellArg cfg.snapshotPrefix}
          mkdir -p "$MNT/nix/safe" "$SNAPSHOT_DIR" "$MNT/nix/tmp" "$MNT/backup/tmp"

          for vol in "$MNT/nix/safe/"* ; do
            [[ "$vol" == "$MNT/nix/safe/*" ]] && break
            NAME="$(basename "$vol")"
            [[ -e "$SNAPSHOT_DIR/$NAME.$TS" ]] && continue

            rm -rf "$MNT/nix/tmp/$NAME"
            btrfs subvolume snapshot -r "$vol" "$MNT/nix/tmp/$NAME"

            if [[ -d "$SNAPSHOT_DIR/$NAME" ]]; then
              btrfs send -p "$MNT/nix/tmp/$NAME" "$SNAPSHOT_DIR/$NAME" | btrfs receive -m "$MNT/backup/tmp"
              btrfs subvolume delete "$MNT/backup/safe/$NAME"
            else
              btrfs send "$MNT/nix/tmp/$NAME" | btrfs receive "$MNT/backup/tmp"
            fi

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

          exec 4>&-
          rm "$PIDFILE" || :
        '';

        my-backup = pkgs.writeScriptBin "backup.bash" ''
          #!${pkgs.stdenv.shell}
          shopt -s nullglob globstar
          export PATH="${pkgs.util-linux}/bin:${pkgs.gnugrep}/bin:$PATH"
          export PATH="${pkgs.rclone}/bin:${pkgs.mktemp}/bin:$PATH"

          if [ "$(id -u)" != 0 ]; then
            echo "Error: Must run ''${0} as root" >&2
            exit 1
          fi

          MNT="$(mktemp -d)"
          BUCKET=${escapeShellArg cfg.bucket}
          DATE="$(date '+%Y-%m-%d-%H:%M:%S')"
          PIDFILE="/var/run/backupdisk.pid"
          SNAPSHOT_DIR="$MNT/"${escapeShellArg cfg.snapshotPrefix}

          touch "$PIDFILE"
          exec 4<"$PIDFILE"
          flock 4

          mount ${escapeShellArg cfg.localSnapshotDrive} "$MNT"
          mkdir -p "$MNT/safe"

          for snap in "$SNAPSHOT_DIR/"*; do
            [[ "$snap" == "$SNAPSHOT_DIR/*" ]] && break
            [[ -d "$snap" ]] || continue
            NAME="$(basename "$snap")"
            grep --quiet "\\." <<< "$NAME" && continue

            ${pkgs.rclone}/bin/rclone --config ${config.sops.templates."rclone.conf".path}  \
              sync "$snap" "backblaze:$BUCKET/LATEST/$NAME" --links -P --backup-dir \
              "backblaze:$BUCKET/$DATE/$NAME"
          done

          umount "$MNT"
          rmdir "$MNT"

          exec 4>&-
          rm "$PIDFILE" || :
        '';
      })
    ];

    environment.systemPackages = with pkgs; [
      rclone
      my-snapshot
      my-backup
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
          script = "${pkgs.my-snapshot}/bin/snapshot.bash";
          path = [pkgs.nix];
          serviceConfig = {
            Type = "oneshot";
            RestartSec = "5min";
          };
        };

        backup = {
          description = "Incremental backup to the cloud";
          script = "${pkgs.my-backup}/bin/backup.bash";
          path = [pkgs.nix];
          serviceConfig = {
            Type = "oneshot";
            RestartSec = "5min";
          };
          requires = ["network.target" "btrfs-snapshots.service"];
        };
      };
    };
  };
}
