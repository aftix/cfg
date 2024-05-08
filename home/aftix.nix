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
    ./opt/vault.nix

    ./opt/chromium.nix
    ./opt/firefox.nix

    ./opt/email.nix

    ./opt/dunst.nix
    ./opt/hypr.nix
    ./opt/kitty.nix
    ./opt/media.nix
    ./opt/stylix.nix
    ./opt/transmission.nix

    ./opt/discord.nix
    ./opt/element.nix
  ];

  nixpkgs.overlays = [
    (_: prev: let
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
      link-gh-hosts = prev.writeScriptBin "link-gh-hosts" ''
        #!${prev.stdenv.shell}
        [[ -f ${secretPath} ]] || exit 1
        TOKEN="$(cat ${secretPath})"
        echo ${hostTemplate} > ${cfg}/gh/hosts.yml
        ${pkgs.gnused}/bin/sed -i"" -e "s/PLACEHOLDER/$TOKEN/g" ${cfg}/gh/hosts.yml
      '';
    })
  ];

  sops.secrets.gh_oauth_token = {};

  home = {
    username = "aftix";
    homeDirectory = "/home/aftix";
    stateVersion = "23.11"; # DO NOT CHANGE

    packages = with pkgs; [
      link-gh-hosts
      weechat-unwrapped
      weechatScripts.weechat-notify-send
    ];

    sessionVariables = {
      WEECHAT_HOME = dataHome + "/weechat";
    };
  };

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

  my = {
    shell.elvish.enable = true;
    docs = {
      enable = true;
      prefix = "hamilton";
    };
  };
}
