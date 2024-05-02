{
  lib,
  home-impermanence,
  sops-nix,
  config,
  upkgs,
  ...
}: let
  mylib = import ./mylib.nix {inherit lib config;};
in {
  _module.args.mylib = mylib;

  imports = [
    home-impermanence
    sops-nix
    ./myoptions.nix

    ./aria2.nix
    ./dunst.nix
    ./elvish.nix
    ./email.nix
    ./firefox.nix
    ./helix.nix
    ./hypr.nix
    ./kitty.nix
    ./machine.nix
    ./mpd.nix
    ./scripts.nix
    ./stylix.nix
    ./transmission.nix
    ./vcs.nix
    ./waybar.nix
  ];

  sops = {
    defaultSopsFile = ./secrets.yaml;

    age.keyFile = "${config.home.homeDirectory}/.local/persist/.config/sops/age/keys.txt";

    secrets = {
      "private_keys/aftix".path = "${config.home.homeDirectory}/.ssh/id_ed25519";
    };
  };

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
        ".config/sops"

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

    sessionVariables = let
      hDir = config.home.homeDirectory;
    in {
      NIXOS_OZONE_WL = "1";

      LESSHISTFILE = "-";
      HISTFILE = "${hDir}/.local/state/bash/history";
      PYTHONSTARTUP = "${hDir}/.config/python/pythonrc";
      RUSTUP_HOME = "${hDir}/.local/state/rustup";
      CARGO_HOME = "${hDir}/.local/state/cargo";
      CARGO_INSTALL_ROOT = "${hDir}/.local/share/bin";
    };

    packages = with upkgs; [
      nil
      statix
      alejandra
      nix-doc
      manix
      sops
      age

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
      zenith
      ssh-agents
      weechat-unwrapped
      weechatScripts.weechat-notify-send

      element-desktop
      discord
      betterdiscordctl

      (import ./documentation.nix {
        inherit lib mylib config;
        pkgs = upkgs;
      })
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
        Unit = {
          Description = "Refresh gpg keys";
          Requires = ["network.target"];
        };
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
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = 600;
      };
      Install.WantedBy = ["timers.target"];
    };
  };

  fonts.fontconfig.enable = true;

  programs = {
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

      scripts = [
        upkgs.mpvScripts.mpris
      ];
    };

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

    # Github cli
    gh = {
      enable = true;

      settings = {
        git_protocol = "ssh";
        prompt = "true";
        aliases.co = "pr checkout";
      };
    };

    home-manager.enable = true;
  };

  xdg = {
    enable = true;

    # Setup XDG_* variables
    configHome = "${config.home.homeDirectory}/.config";
    dataHome = "${config.home.homeDirectory}/.local/share";
    cacheHome = "${config.home.homeDirectory}/.cache";
    stateHome = "${config.home.homeDirectory}/.local/state";

    userDirs = {
      enable = true;
      desktop = null;
      documents = "${config.home.homeDirectory}/doc";
      music = "${config.home.homeDirectory}/media/music";
      pictures = "${config.home.homeDirectory}/media/img";
      publicShare = "${config.home.homeDirectory}/media/sync";
      videos = "${config.home.homeDirectory}/media/video";
    };

    portal = {
      enable = true;
      extraPortals = [upkgs.xdg-desktop-portal-hyprland];
      configPackages = [upkgs.xdg-desktop-portal-hyprland];
      config.preferred.default = "xdg-desktop-portal-hyprland";
    };

    # Setup xdg default programs
    mime.enable = true;
    mimeApps = {
      enable = true;
      defaultApplications = mylib.registerMimes [
        {
          application = "zathura";
          mimetypes = [
            "application/pdf"
            "application/x-pdf"
            "application/epub"
          ];
        }
        {
          application = "feh";
          mimetypes = [
            "image/bmp"
            "image/apng"
            "image/png"
            "image/tiff"
            "image/jpeg"
            "image/gif"
            "image/vnd.microsoft.icon"
            "image/tiff"
          ];
        }
        {
          application = "mpv";
          mimetypes = [
            "image/avif"
            "video/mp4"
            "video/avi"
            "application/x-msvideo"
            "video/mkv"
            "video/mpeg"
            "video/webm"
            "audio/aac"
            "audio/flac"
            "audio/ogg"
            "audio/mp3"
          ];
        }
      ];
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

      # npm
      "npm/npmrc".source = (upkgs.formats.keyValue {}).generate "npm" {
        prefix = "\${XDG_DATA_HOME}/npm";
        cache = "\${XDG_CACHE_HOME}/npm";
        init-module = "\${XDG_CONFIG_HOME}/npm/config/npm-init.js";
        logs-dir = "\${XDG_CACHE_HOME}/npm/logs";
      };

      # Python
      "python/pythonrc".text = ''
        def is_vanilla() -> bool:
          import sys
          return not hasattr(__builtins__, '__IPYTHON__') and 'bpython' not in sys.argv[0]

        def setup_history():
          import os
          import atexit
          import readline
          from pathlib import Path

          if state_home := os.environ.get('XDG_STATE_HOME'):
              state_home = Path(state_home)
          else:
              state_home = Path.home() / '.local' / 'state'

          history: Path = state_home / 'python_history'

          readline.read_history_file(str(history))
          atexit.register(readline.write_history_file, str(history))

        if is_vanilla():
          setup_history()
      '';
    };
  };

  mydocs = {
    enable = true;
    prefix = "hamilton";
  };
}
