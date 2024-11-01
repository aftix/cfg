{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib.strings) escapeShellArg;

  inherit (config.xdg) configHome dataHome;
in {
  imports = [
    ./common
    ../hardware/hamilton-home.nix

    ./opt/impermanence.nix
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

    ./opt/discord.nix
    ./opt/element.nix
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
      link-gh-hosts
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
      ExecStart = "${pkgs.link-gh-hosts}/bin/link-gh-hosts";
    };
    Install.WantedBy = ["default.target"];
  };

  home.persistence.${config.my.impermanence.path} = {
    directories = [
      ".config/attic"
      ".config/keepassxc"
      ".config/Yubico"
    ];
    files = [
      ".config/nushell/history.sqlite3"
      ".config/nushell/history.sqlite3-shm"
      ".config/nushell/history.sqlite3-wal"
    ];
  };

  my = {
    shell = {
      elvish.enable = true;
      nushell.enable = true;
    };
    docs = {
      enable = true;
      prefix = "hamilton";
    };
  };

  programs.gpg.settings.default-key = "294D241578ED5CD1";
}
