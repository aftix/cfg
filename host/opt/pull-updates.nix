# Pull NixOS updates from repo on a schedule
{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkOption types;

  cfg = config.aftix.pull-updates;

  updateScript = pkgs.writeNushellApplication {
    name = "update-nixos.nu";
    runtimeInputs = with pkgs; [git nixos-rebuild-ng nix];
    text =
      /*
      nu
      */
      ''
        use std/log

        def main [] {
          if (id -u | into int) != 0 {
            log critical "This script must be run as root"
            error make { msg: $"Must run ($env.CURRENT_FILE) as root" }
          }

          let repoDir = (mktemp -d)

          try {
            rm -rf $repoDir

            log info $"Cloning ${cfg.branch} into ($repoDir)"
            git clone -b r#'${cfg.branch}'# --single-branch --depth 1 ${lib.escapeShellArg cfg.repo} $repoDir
            cd $repoDir

            log info "Switching into ${cfg.attrPath}"
            nixos-rebuild-ng --no-reexec --attr r#'${cfg.attrPath}'# switch
          } catch {
            log critical "Failed to switch to configuration"
            log info "Cleaning up"
            cd /
            rm -rf $repoDir
            error make {msg: "Failed to switch to configuration"}
          }

          log info "Cleaning up"
          cd /
          rm -rf $repoDir
        }
      '';
  };
in {
  options.aftix.pull-updates = {
    enable = mkEnableOption "aftix pull-updates";

    repo = mkOption {
      default = "https://${config.aftix.statics.codeForge}/aftix/cfg.git";
      type = types.uniq types.str;
      description = "URL of repository containing the NixOS Configurations";
    };

    branch = mkOption {
      default = "main";
      type = types.uniq types.str;
      description = "Branch to build from";
    };

    configuration-name = mkOption {
      default = config.networking.hostName;
      type = types.uniq types.str;
      description = "Name of nixos configuration to build from the repository";
    };

    attrPath = mkOption {
      default = "nixosConfigurations.${cfg.configuration-name}";
      type = types.uniq types.str;
      description = "Attrpath of evaluated nixos system in the repository";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd = {
      timers.nixos-pull-updates = {
        description = "Pull system updates from ${cfg.repo}";
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "daily";
          Persist = true;
          RandomizedDelaySec = 1800;
        };
      };

      services.nixos-pull-updates = {
        description = "Pull system updates from ${cfg.repo}";
        after = lib.flatten (lib.mapAttrsToList (name: value:
          if value != {}
          then "restic-backups-${name}.service"
          else [])
        config.services.restic.backups);

        path = [pkgs.systemd];
        serviceConfig.Type = "oneshot";
        script = ''
          systemd-inhibit \
            --mode=block --why="Updating NixOS configuration" --who="nixos-pull-updates.service $$" \
            ${lib.getExe updateScript}
        '';
      };
    };
  };
}
