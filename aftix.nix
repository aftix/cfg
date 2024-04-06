{ upkgs, spkgs, ... }:

{
  imports = [
    ./aftix/mpd.nix
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
    python312Packages.aria2p
  ];

  home.stateVersion = "23.11";
  programs.home-manager.enable = true;
}
