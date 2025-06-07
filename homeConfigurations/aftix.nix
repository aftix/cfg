# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  config,
  osConfig,
  pkgs,
  lib,
  ...
}: let
  inherit (lib.lists) optionals;
  inherit (lib.strings) escapeShellArg;

  inherit (config.xdg) configHome dataHome;

  link-gh-hosts = let
    hostTemplate = escapeShellArg (builtins.toJSON {
      "github.com" = {
        users.aftix.oauth_token = "PLACEHOLDER";
        git_protocol = "ssh";
        user = "aftix";
        oauth_token = "PLACEHOLDER";
      };
    });
    secretPath = escapeShellArg config.sops.secrets.gh_oauth_token.path;
    cfg = escapeShellArg configHome;
  in
    pkgs.writeShellApplication {
      name = "link-gh-hosts";
      runtimeInputs = with pkgs; [gnused];
      text = ''
        [[ -f ${secretPath} ]] || exit 1
        TOKEN="$(cat ${secretPath})"
        echo ${hostTemplate} > ${cfg}/gh/hosts.yml
        sed -i"" -e "s/PLACEHOLDER/$TOKEN/g" ${cfg}/gh/hosts.yml
      '';
    };
in {
  imports = [
    ../hardware/hamilton-home.nix

    ../extraHomemanagerModules/sops.nix

    ../extraHomemanagerModules/aria2.nix
    ../extraHomemanagerModules/development.nix
    ../extraHomemanagerModules/helix.nix
    ../extraHomemanagerModules/neoutils.nix

    ../extraHomemanagerModules/firefox.nix

    ../extraHomemanagerModules/email.nix

    ../extraHomemanagerModules/hypr.nix
    ../extraHomemanagerModules/kitty.nix
    ../extraHomemanagerModules/media.nix
    ../extraHomemanagerModules/stylix.nix
    ../extraHomemanagerModules/swaync.nix
    ../extraHomemanagerModules/transmission.nix
    ../extraHomemanagerModules/zathura.nix

    ../extraHomemanagerModules/discord.nix
  ];

  sops.secrets.gh_oauth_token = {};

  home = {
    username = "aftix";
    homeDirectory = "/home/aftix";
    stateVersion = "23.11"; # DO NOT CHANGE

    packages = with pkgs; [
      attic-client
    ];

    sessionVariables = {
      WEECHAT_HOME = dataHome + "/weechat";
      SSH_ASKPASS = lib.getExe pkgs.ssh-askpass-fullscreen;
    };
  };

  services.swaync.enable = true;

  systemd.user.services = {
    ghHosts = {
      Unit = {
        Description = "create gh hosts file";
        After = ["sops-nix.service"];
      };
      Service = {
        Type = "oneshot";
        Restart = "on-failure";
        RestartSec = "1s";
        ExecStart = lib.getExe link-gh-hosts;
      };
      Install.WantedBy = ["default.target"];
    };

    ssh-agent.Service.Environment = "SSH_ASKPASS=${config.home.sessionVariables.SSH_ASKPASS}";
  };

  aftix = {
    matrixClient = pkgs.fractal;

    shell = {
      nushell = {
        enable = true;
        extraCommands = optionals pkgs.stdenv.hostPlatform.isLinux [
          {
            name = "\"limit mem\"";
            arguments = ''
              --soft: string
              --hard: string
              --swap: string
              ...args
            '';
            body = ''
              mut args = $args
              if $soft != null {
                $args = ["-p" $"MemoryHigh=($soft)" ...$args]
              }
              if $hard != null {
                $args = ["-p" $"MemoryMax=($hard)" ...$args]
              }
              if $swap != null {
                $args = ["-p" $"MemorySwapMax=($swap)" ...$args]
              }
              systemd-run --user --slice-inherit -dtP ...$args
            '';
          }
        ];
      };
    };
    docs = {
      enable = true;
      prefix = let
        host = osConfig.networking.hostName or "";
      in
        if host == ""
        then "nixos"
        else host;
    };
  };

  programs.gpg.settings.default-key = "294D241578ED5CD1";
}
