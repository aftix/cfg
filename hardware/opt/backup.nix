{pkgs, ...}: {
  nixpkgs.overlays = [
    (final: prev: {
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
        TWO_MONTHS_AGO="$(date -d 'now - 2 months' +%s)"

        touch "$PIDFILE"
        exec 4<"$PIDFILE"
        flock 4

        echo "$$" > "$PIDFILE"

        mkdir "$MNT/nix" "$MNT/backup"

        mount /dev/disk/by-label/nixos "$MNT/nix"
        mount /dev/disk/by-label/mass "$MNT/backup"

        mkdir -p "$MNT/nix/safe" "$MNT/backup/safe" "$MNT/nix/tmp" "$MNT/backup/tmp"

        for vol in "$MNT/nix/safe/"* ; do
          [[ "$vol" == "$MNT/nix/safe/*" ]] && break
          NAME="$(basename "$vol")"
          [[ -e "$MNT/backup/safe/$NAME.$TS" ]] && continue

          rm -rf "$MNT/nix/tmp/$NAME"
          btrfs subvolume snapshot -r "$vol" "$MNT/nix/tmp/$NAME"

          if [[ -d "$MNT/backup/safe/$NAME" ]]; then
            btrfs send -p "$MNT/nix/tmp/$NAME" "$MNT/backup/safe/$NAME" | btrfs receive -m "$MNT/backup/tmp"
            btrfs subvolume delete "$MNT/backup/safe/$NAME"
          else
            btrfs send "$MNT/nix/tmp/$NAME" | btrfs receive "$MNT/backup/tmp"
          fi

          btrfs subvolume snapshot -r "$MNT/backup/tmp/$NAME" "$MNT/backup/safe/$NAME"
          btrfs subvolume snapshot -r "$MNT/backup/tmp/$NAME" "$MNT/backup/safe/$NAME.$TS"
          btrfs subvolume delete "$MNT/nix/tmp/$NAME"
        done

        rmdir "$MNT/nix/tmp"
        umount "$MNT/nix"

        for snap in "$MNT/backup/safe/"*; do
          [[ "$snap" == "$MNT/backup/safe/*" ]] && break
          [[ -d "$snap" ]] || continue
          MTIME="$(date -r "$snap" +%s)"
          (( MTIME <= TWO_MONTHS_AGO )) && btrfs subvolume delete "$snap"
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
        BUCKET="aftix-hamilton-backup"
        DATE="$(date '+%Y-%m-%d-%H:%M:%S')"
        PIDFILE="/var/run/backupdisk.pid"

        touch "$PIDFILE"
        exec 4<"$PIDFILE"
        flock 4

        mount /dev/disk/by-label/mass "$MNT"
        mkdir -p "$MNT/safe"

        for snap in "$MNT/safe/"*; do
          [[ "$snap" == "$MNT/backup/safe/*" ]] && break
          [[ -d "$snap" ]] || continue
          NAME="$(basename "$snap")"
          grep --quiet "\\." <<< "$NAME" && continue

          ${pkgs.rclone}/bin/rclone sync "$snap" "backblaze:$BUCKET/LATEST/$NAME" --links -P --backup-dir "backblaze:$BUCKET/$DATE/$NAME"
        done

        umount "$MNT"
        rmdir "$MNT"

        exec 4>&-
        rm "$PIDFILE" || :
      '';
    })
  ];
  environment = {
    systemPackages = with pkgs; [
      rclone
      my-snapshot
      my-backup
    ];
  };

  systemd = {
    timers = {
      btrfs-snapshots = {
        description = "Daily incremental BtrFS snapshots";
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
          RandomizedDelaySec = 600;
        };
      };

      backup = {
        description = "Monthly incremental backups to the cloud";
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "*-*-01 06:00:00";
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
}
