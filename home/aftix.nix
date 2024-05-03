{
  config,
  upkgs,
  mylib-builder,
  ...
}: let
  mylib = mylib-builder config;
in {
  _module.args.mylib = mylib;

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

  sops = {};

  home = {
    username = "aftix";
    homeDirectory = "/home/aftix";
    stateVersion = "23.11"; # DO NOT CHANGE

    packages = with upkgs; [
      weechat-unwrapped
      weechatScripts.weechat-notify-send
    ];

    sessionVariables = {
      WEECHAT_HOME = "${config.xdg.dataHome}/weechat";
    };
  };

  my = {
    shell.elvish.enable = true;
    docs = {
      enable = true;
      prefix = "hamilton";
    };
  };
}
