{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib.lists) optionals;
  inherit (lib.strings) escapeShellArg;

  inherit (config.xdg) configHome dataHome;
in {
  imports = [
    ./common
    ../hardware/hamilton-home.nix

    ./opt/sops.nix

    ./opt/aria2.nix
    ./opt/development.nix
    ./opt/helix.nix
    ./opt/neoutils.nix

    ./opt/firefox.nix

    ./opt/email.nix

    ./opt/hypr.nix
    ./opt/kitty.nix
    ./opt/media.nix
    ./opt/stylix.nix
    ./opt/swaync.nix
    ./opt/transmission.nix
    ./opt/zathura.nix

    ./opt/discord.nix
  ];

  nixpkgs.overlays = [
    (final: _: let
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
    in {
      link-gh-hosts = final.writeShellApplication {
        name = "link-gh-hosts";
        runtimeInputs = with final; [gnused];
        text = ''
          [[ -f ${secretPath} ]] || exit 1
          TOKEN="$(cat ${secretPath})"
          echo ${hostTemplate} > ${cfg}/gh/hosts.yml
          sed -i"" -e "s/PLACEHOLDER/$TOKEN/g" ${cfg}/gh/hosts.yml
        '';
      };
    })
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
    };
  };

  services.swaync.enable = true;

  systemd.user.services.ghHosts = {
    Unit = {
      Description = "create gh hosts file";
      After = ["sops-nix.service"];
    };
    Service = {
      Type = "oneshot";
      Restart = "on-failure";
      RestartSec = "1s";
      ExecStart = "${lib.getExe pkgs.link-gh-hosts}";
    };
    Install.WantedBy = ["default.target"];
  };

  my = {
    matrixClient = pkgs.fractal;

    shell = {
      elvish.enable = true;
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
        host = config.my.nixosCfg.networking.hostName or "";
      in
        if host == ""
        then "nixos"
        else host;
    };
  };

  programs.gpg.settings.default-key = "294D241578ED5CD1";
}
