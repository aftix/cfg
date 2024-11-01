{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib.strings) escapeShellArg removePrefix concatLines optionalString;
  cfg = config.my.backup;
in {
  options.my.backup = {
    bucket = mkOption {
      default = "";
      type = lib.types.str;
    };

    directories = mkOption {default = ["/var/lib"];};
    excludes = mkOption {default = [];};
    backupOnCalendar = mkOption {default = "daily";};
  };

  config = {
    nixpkgs.overlays = [
      (final: _: {
        my-basic-backup = final.writeShellApplication {
          name = "backup.bash";
          runtimeInputs = with final; [gnugrep rclone util-linux mktemp];
          text = let
            excludes = optionalString (cfg.excludes != []) (builtins.concatStringsSep " " (builtins.map (s: "--exclude " + escapeShellArg s) cfg.excludes));
            dirName = s: escapeShellArg (removePrefix "/" s);
            backups = map (dir:
              /*
              bash
              */
              ''
                rclone --config ${config.sops.templates."rclone.conf".path} \
                  sync ${escapeShellArg dir} "backblaze:$BUCKET/LATEST/"${dirName dir} \
                  --links -P --backup-dir "backblaze:$BUCKET/$DATE/"${dirName dir} \
                  ${excludes} --delete-excluded || :
              '')
            cfg.directories;
          in
            /*
            bash
            */
            ''
              shopt -s nullglob globstar

              if [ "$(id -u)" != 0 ]; then
                echo "Error: Must run ''${0} as root" >&2
                exit 1
              fi

              function cleanup() {
                [[ -f /var/run/backupdisk.pid ]] && (rm /var/run/backupdisk.pid || :)
              }
              trap cleanup EXIT
              echo "$$" > /var/run/backupdisk.pid

              BUCKET=${escapeShellArg cfg.bucket}
              DATE="$(date '+%Y-%m-%d-%H:%M:%S')"

              ${concatLines backups}
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
      timers.backup = {
        description = "Daily incremental backups to the cloud";
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = cfg.backupOnCalendar;
          Persistent = true;
          RandomizedDelaySec = 600;
        };
      };

      services.backup = {
        description = "Incremental backup to the cloud";
        after = ["network-online.target"];
        requires = ["network-online.target"];
        path = [pkgs.nix];

        script = ''
          cd / || exit 1
          LOCKFILE="/var/run/backupdisk"
          LOCKFD=99
          _lock() { ${lib.getExe pkgs.flock} -"$1" "$LOCKFD"; }
          _no_more_locking() { _lock u ; _lock xn && rm -f "$LOCKFILE"; }
          _prepare_locking() { eval "exec $LOCKFD>\"$LOCKFILE\""; trap _no_more_locking EXIT; }
          _prepare_locking

          _lock xn || exit 1
          ${lib.getExe pkgs.my-basic-backup} >/var/log/backup 2>/var/log/backup.err
        '';
        serviceConfig = {
          Type = "simple";
          RestartSec = "5min";
        };
      };
    };
  };
}
