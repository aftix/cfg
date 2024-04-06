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
    ./waybar.nix
  ];

  home.username = "aftix";
  home.homeDirectory = "/home/aftix";

  home.packages = with upkgs; [
    rustup go sccache
    firefox-bin ungoogled-chromium
    pipx conda
    tealdeer
    pavucontrol pass xdotool
    vault
    gh
    fontconfig
    kitty kitty-img kitty-themes
    element-desktop discord betterdiscordctl
    tofi slurp libnotify notify-desktop
    weechat-unwrapped weechatScripts.weechat-notify-send
  ];

  # Various minor configs

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

  # Hyprland - just symlink as config is pretty dynamic
  home.activation = {
    linkHypr = ''
      export ROOT="${config.home.homeDirectory}/src/cfg/home/aftix"
      ln -sf "$ROOT/_external.hypr" .config/hypr
    '';
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

  # tealdeer
  xdg.configFile."teeldeer/config.toml".text = builtins.toJSON {
    display.use_pager = true;
    updates.auto_update = true;
    style = {
      command_name.foreground = "green";
      example_code.foreground = "blue";
      example_variable = {
        foreground = "white";
        underline = true;
      };
    };
  };

  # tofi macchiato
  xdg.configFile."tofi/config".text = ''
    text-color = #cad3f5
    prompt-color = #ed8796
    selection-color = #eed49f
    background-color = #24273a
  '';

  # mpv
  programs.mpv = {
    enable = true;
    config = {
      slang = "en";
      vo = "gpu";
      video-sync = "display-resample";
      interpolation = true;
      tscale = "oversample";
      hwdec = "best";
      ytdl-format = "bestvideo[height<=1080]+bestaudio/best[height<=1080]/bestvideo+bestaudio/best";
      save-position-on-quit = true;
      sub-font = "Source Han Serif JP";
      sub-auto= "fuzzy";
    };
    profiles = {
      "extension.gif".loop-file = "inf";
      "extension.jpg" = {
        pause = true;
        border = false;
        osc = false;
      };
      "extension.png" = {
        pause = true;
        border = false;
        osc = false;
      };
    };
  };

  # Zathura
  programs.zathura = {
    enable = true;
    options = {
      guioptions = "none";
      statusbar-h-padding = 0;
      statusbar-v-padding = 0;
      page-padding = 1;
    };
    mappings = {
      u = "scroll half-up";
      e = "scroll half-down";
      H = "toggle_page_mode";
      g = "zoom in";
      c = "zoom out";
      r = "reload";
      i = "recolor";
      p = "print";
      h = "scroll left";
      j = "scroll down";
      k = "scroll up";
      l = "scroll right";
      d = "follow";
      z = "quit";
      f = "goto 1";
      A = "adjust_window width";
      R = "rotate";
    };
  };
  
  # Home manager
  home.stateVersion = "23.11";
  programs.home-manager.enable = true;
}
