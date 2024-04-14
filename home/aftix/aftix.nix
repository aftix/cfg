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
    ./firefox.nix
    ./helix.nix
    ./hypr.nix
    ./kitty.nix
    ./mpd.nix
    ./scripts.nix
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

    packages = with upkgs; [
      nil
      statix
      alejandra
      nix-doc
      nix-search-cli
      manix

      markdown-oxide

      rustup
      sccache
      cargo-nextest
      cargo-supply-chain
      cargo-update
      cargo-llvm-cov
      cargo-sort
      cargo-udeps
      cargo-crev

      lldb
      clang
      clang-tools

      go
      golint
      delve

      mypy
      python311Packages.flake8
      python311Packages.python-lsp-server
      python311Packages.pyls-flake8
      python311Packages.pylsp-mypy
      pipx
      conda

      nodePackages.bash-language-server

      ffmpeg_5
      jq
      imagemagick

      aspell
      aspellDicts.en
      aspellDicts.en-science
      aspellDicts.en-computers

      pass
      xdotool
      hyperfine
      tealdeer
      vault
      gh
      zenith
      ssh-agents
      weechat-unwrapped
      weechatScripts.weechat-notify-send

      element-desktop
      discord
      betterdiscordctl
    ];
  };

  # Various minor configs
  programs = {
    yt-dlp.enable = true;
    starship = {
      enable = true;
      settings = {
        "$schema" = "https://starship.rs/config-schema.json";
        add_newline = true;
        package.disabled = true;
      };
    };

    password-store = {
      enable = true;
      settings.PASSWORD_STORE_DIR = "${config.home.homeDirectory}/.local/share/password-store";
    };

    gpg = {
      enable = true;
      homedir = "${config.home.homeDirectory}/.local/share/gnupg";

      settings = {
        keyserver = "keys.gnupg.net";
      };
    };

    chromium = {
      enable = true;
      package = upkgs.ungoogled-chromium;
      dictionaries = [upkgs.hunspellDictsChromium.en_US];
    };
  };

  services = {
    clipman.enable = true;
    gpg-agent = {
      enable = true;
      extraConfig = ''
        pinentry-program ${config.home.homeDirectory}/.config/bin/pinentry-custom
      '';
    };
    ssh-agent.enable = true;
  };

  systemd.user = {
    startServices = true;
    services = {
      linkGh = let
        cfg = "${config.home.homeDirectory}/.config";
        share = "${config.home.homeDirectory}/.local/share";
      in {
        Unit.Description = "Link gh hosts file";
        Service = {
          Type = "oneshot";
          ExecStart = ''
            ${upkgs.coreutils}/bin/mkdir -p "${cfg}/gh" ; \
            ${upkgs.coreutils}/bin/ln -sf "${share}/gh/hosts.yml" "${cfg}/gh/hosts.yml"
          '';
        };
        Install.WantedBy = ["default.target"];
      };
      keyrefresh = {
        Unit.Description = "Refresh gpg keys";
        Service = {
          Type = "oneshot";
          Environment = ''GNUPGHOME="${config.programs.gpg.homedir}"'';
          ExecStart = "${upkgs.gnupg}/bin/gpg --refresh-keys";
        };
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
      };
    };

    configFile = {
      # Fontconfig
      # TODO: make XML generator
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
      "tealdeer/config.toml".source = (upkgs.formats.toml {}).generate "tealdeer" {
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
      "tofi/config".source = (upkgs.formats.keyValue {}).generate "tofi" {
        text-color = "#cad3f5";
        prompt-color = "#ed8796";
        selection-color = "#eed49f";
        background-color = "#24273a";
      };

      # npm
      "npm/npmrc".source = (upkgs.formats.keyValue {}).generate "npm" {
        prefix = "\${XDG_DATA_HOME}/npm";
        cache = "\${XDG_CACHE_HOME}/npm";
        init-module = "\${XDG_CONFIG_HOME}/npm/config/npm-init.js";
        logs-dir = "\${XDG_CACHE_HOME}/npm/logs";
      };
    };
  };
}
