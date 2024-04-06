{ home-impermanence, upkgs, spkgs, ... }:

{
  imports = [
    home-impermanence
    ./aria2.nix
    ./elvish.nix
    ./mpd.nix
    ./helix.nix
  ];

  home.username = "aftix";
  home.homeDirectory = "/home/aftix";

  home.packages = with upkgs; [
    rustup go sccache
    firefox-bin ungoogled-chromium
    pipx conda
    pavucontrol pass xdotool
    vault
    gh
    element-desktop discord betterdiscordctl
    tofi slurp libnotify notify-desktop
    weechat-unwrapped weechatScripts.weechat-notify-send
  ];

  programs.starship.settings = {
    "$schema" = "https://starship.rs/config-schema.json";
    add_newline = true;
    package.disabled = true;
  };

  home.stateVersion = "23.11";
  programs.home-manager.enable = true;
}
