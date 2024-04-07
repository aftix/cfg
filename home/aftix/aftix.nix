{
  home-impermanence,
  config,
  upkgs,
  ...
}: {
  imports = [
    home-impermanence
    ./aria2.nix
    ./dunst.nix
    ./elvish.nix
    ./email.nix
    ./helix.nix
    ./kitty.nix
    ./mpd.nix
    ./transmission.nix
    ./vcs.nix
    ./waybar.nix
  ];

  home = {
    username = "aftix";
    homeDirectory = "/home/aftix";
    stateVersion = "23.11"; # DO NOT CHANGE

    # Discord, element, and chromium store state in .config for some reason
    # symlink them from ~/.local/persist on boot so ~/.config is a tmpfs
    # Some of the data in transmission's config dir should be in XDG_DATA_HOME
    # Impermenance is used to persist it
    persistence."${config.home.homeDirectory}/.local/persist" = {
      directories = [
        ".config/discord"
        ".config/BetterDiscord"
        ".config/chromium"
        ".config/Element"

        ".config/transmission/torrents"
        ".config/transmission/blocklists"
        ".config/transmission/resume"
      ];
      files = [
        ".config/transmission/dht.dat"
        ".config/transmission/stats.json"
        ".config/transmission/bandwidth-groups.json"
      ];
      allowOther = true;
    };

    sessionVariables = {
      XDG_CURRENT_DESKTOP = "Hyprland";
      MOZ_USE_XINPUT2 = "1";
    };

    packages = with upkgs; [
      nil
      ffmpeg_5
      jq
      imagemagick
      statix
      alejandra
      hyprland
      hyprlock
      hypridle
      hyprpaper
      hyprcursor
      xdg-desktop-portal-hyprland
      hyprland-protocols
      clipman
      rustup
      go
      sccache
      (wrapFirefox (firefox-unwrapped.override {pipewireSupport = true;}) {})
      ungoogled-chromium
      pipx
      conda
      tealdeer
      pavucontrol
      pass
      xdotool
      vault
      gh
      fontconfig
      element-desktop
      discord
      betterdiscordctl
      tofi
      slurp
      libnotify
      wl-clipboard
      xclip
      aspell
      aspellDicts.en
      aspellDicts.en-science
      aspellDicts.en-computers
      zenith
      ssh-agents
      weechat-unwrapped
      weechatScripts.weechat-notify-send
      udiskie
      pinentry-gtk2
      yt-dlp
      mpv
    ];

    activation = {
      # Hyprland - just symlink as config is pretty dynamic
      linkHyp = ''
        export ROOT="${config.home.homeDirectory}/src/cfg/home/aftix"
        [ -e .config/hypr ] && rm .config/hypr
        ln -sf "$ROOT/_external.hypr/" .config/hypr
      '';

      # link GH auth into .config
      ghAuth = ''
        export ROOT="${config.home.homeDirectory}"
        mkdir -p .config/gh
        ln -sf "$ROOT/.local/share/gh/hosts.yml" .config/gh/hosts.yml
      '';
    };
  };

  # Various minor configs
  programs = {
    yt-dlp.enable = true;
    starship.settings = {
      "$schema" = "https://starship.rs/config-schema.json";
      add_newline = true;
      package.disabled = true;
    };

    gpg = {
      enable = true;
      homedir = "${config.home.homeDirectory}/.local/share/gnupg";

      settings = {
        keyserver = "keys.gnupg.net";
      };
    };

    firefox.enable = true;
    chromium = {
      enable = true;
      package = upkgs.ungoogled-chromium;
      dictionaries = [upkgs.hunspellDictsChromium.en_US];
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false; # Set this to false to prevent generating hyprland.conf
    xwayland.enable = true;
  };

  services = {
    clipman.enable = true;
    gpg-agent = {
      enable = true;
      extraConfig = ''
        pinentry-program ${config.home.homeDirectory}/.local/bin/pinentry-custom
      '';
    };
    udiskie.enable = true;
    ssh-agent.enable = true;
  };

  systemd.user = {
    startServices = true;
    services.keyrefresh = {
      Unit.Description = "Refresh gpg keys";
      Service = {
        Type = "oneshot";
        Environment = ''GNUPGHOME="${config.programs.gpg.homedir}"'';
        ExecStart = "${upkgs.gnupg}/bin/gpg --refresh-keys";
      };
    };

    timers.keyrefresh = {
      Unit.Description = "Refresh gpg keys every 8 hours";
      Timer = {
        OnStartupSec = "1m";
        OnUnitActiveSec = "8h";
      };
      Install.WantedBy = ["timers.target"];
    };

    targets.hyprland-session = {
      Unit = {
        Description = "hyprland target";
        Requires = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };
    };
  };

  fonts.fontconfig.enable = true;

  programs = {
    # mpv
    mpv = {
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
        sub-auto = "fuzzy";
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
    zathura = {
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

    # GH
    gh = {
      enable = true;
      settings = {
        git_protocol = "ssh";
        prompt = "true";
        aliases.co = "pr checkout";
      };
    };

    # Home manager
    home-manager.enable = true;
  };

  # Setup xdg default programs
  xdg = {
    enable = true;

    portal = {
      enable = true;
      extraPortals = [upkgs.xdg-desktop-portal-hyprland];
      configPackages = [upkgs.xdg-desktop-portal-hyprland];
      config.preferred.default = "xdg-desktop-portal-hyprland";
    };

    mime.enable = true;
    mimeApps = {
      enable = true;
      defaultApplications = {
        "application/pdf" = ["zathura.desktop"];
        "application/x-pdf" = ["zathura.desktop"];
        "application/epub" = ["zathura.desktop"];
        "image/png" = ["feh.desktop"];
        "image/tiff" = ["feh.desktop"];
        "image/jpg" = ["feh.desktop"];
        "image/gif" = ["mpv.desktop"];
        "video/mp4" = ["mpv.desktop"];
        "video/avi" = ["mpv.desktop"];
        "video/mkv" = ["mpv.desktop"];
        "video/webm" = ["mpv.desktop"];
        "audio/flac" = ["mpv.desktop"];
        "audio/ogg" = ["mpv.desktop"];
        "audio/mp3" = ["mpv.desktop"];
        "x-scheme-handler/http" = ["firefox.desktop"];
        "x-scheme-handler/https" = ["firefox.desktop"];
        "x-scheme-handler/ftp" = ["firefox.desktop"];
      };
    };

    configFile = {
      # Fontconfig
      "fontconfig/fonts.conf".text = ''
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
      "tealdeer/config.toml".text = ''
        [display]
        use_pager = true

        [updates]
        auto_update = true

        [style.command_name]
        foreground = "green"

        [style.example_code]
        foreground = "blue"

        [style.example_variable]
        foreground = "white"
        underline = true
      '';

      # tofi macchiato
      "tofi/config".text = ''
        text-color = #cad3f5
        prompt-color = #ed8796
        selection-color = #eed49f
        background-color = #24273a
      '';
    };
  };
}
