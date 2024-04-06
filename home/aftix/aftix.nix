{ home-impermanence, config, upkgs, spkgs, ... }:

{
  imports = [
    home-impermanence
    ./aria2.nix
    ./dunst.nix
    ./elvish.nix
    ./mpd.nix
    ./helix.nix
    ./vcs.nix
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
    fontconfig
    kitty kitty-img kitty-themes
    element-desktop discord betterdiscordctl
    tofi slurp libnotify notify-desktop
    weechat-unwrapped weechatScripts.weechat-notify-send
  ];

  programs.starship.settings = {
    "$schema" = "https://starship.rs/config-schema.json";
    add_newline = true;
    package.disabled = true;
  };

  systemd.user.startServices = true;

  # GPG
  programs.gpg = {
    enable = true;
    homedir = "${config.home.homeDirectory}/.local/share/gnupg";
  };
  services.gpg-agent.enable = true;
  systemd.user.services.keyrefresh = {
    Unit.Description = "Refresh gpg keys";
    Service = {
      Type = "oneshot";
      Environment = "GNUPGHOME=\"${config.programs.gpg.homedir}\"";
      ExecStart = "${upkgs.gnupg}/bin/gpg --refresh-keys";
    };
  };
  systemd.user.timers.keyrefresh = {
    Unit.Description = "Refresh gpg keys every 8 hours";
    Timer = {
      OnStartupSec = "1m";
      OnUnitActiveSec = "8h";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  # Fonts
  fonts.fontconfig.enable = true;
  xdg.configFile."fontconfig/fonts.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
    <match target="pattern">
      <test qual="any" name="family"><string>serif</string></test>
      <edit name="family" mode="assign" binding="same"><string>Source Han Serif JP</string></edit>
    </match>
    <match target="pattern">
      <test qual="any" name="family"><string>sans-serif</string></test>
      <edit name="family" mode="assign" binding="same"><string>Source Han Sans JP</string></edit>
    </match>
    <match target="pattern">
      <test qual="any" name="family"><string>monospace</string></test>
      <edit name="family" mode="assign" binding="same"><string>WenQuanYi Zen Hei Mono</string></edit>
    </match>
    </fontconfig>
  '';

  # Home manager
  home.stateVersion = "23.11";
  programs.home-manager.enable = true;
}
