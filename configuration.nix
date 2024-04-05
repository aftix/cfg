{lib, ...}: let
  channels = import ./channels.nix {
    config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "discord"
        "vault"
      ];
    stableconfig = {};
  };
in
  with channels; {
    imports = [
      ./hardware-configuration.nix
      ./machine.nix
      ./impermanence/nixos.nix
    ];

    nix.nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "nixos-config=/home/aftix/src/cfg/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
    nix.settings.experimental-features = ["nix-command" "flakes"];
    nix.gc = {
      automatic = true;
      persistent = true;
      dates = "daily";
      options = "--delete-older-than 30d";
    };

    # Use the systemd-boot EFI boot loader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.systemd-boot.consoleMode = "auto";
    boot.loader.systemd-boot.editor = false;
    boot.loader.systemd-boot.memtest86.enable = true;

    # Opt-in to state

    # /persist is backed up (btrfs subvolume under safe/)
    environment.persistence = {
      "/persist" = {
        hideMounts = true;
        directories = [
          "/var/lib/nixos"
          "/etc/nixos"
          "/etc/NetworkManager/system-connections"
        ];
      };
      # /state is not backup up (btrfs subvolume under local)
      "/state" = {
        hideMounts = true;
        directories = [
          "/var/log"
          "/var/lib/bluetooth"
          "/var/lib/systemd/coredump"
        ];
      };
    };

    # Locales
    time.timeZone = "America/Chicago";
    i18n.defaultLocale = "en_US.UTF-8";
    console = {
      font = "Lat2-Terminus16";
      # keyMap = "us";
      useXkbConfig = true; # use xkb.options in tty.
    };

    # Graphical session
    programs.hyprland.enable = true;
    services.xserver.enable = true;
    services.xserver.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      theme = "${pkgs.catppuccin-sddm-corners}";
      autoNumlock = true;
      settings = {
        General = {
          GreeterEnvironment = "QT_WAYLAND_SHELL_INTEGRATION=layer-shell";
        };
        Autologin = {
          Session = "hyprland";
          User = "aftix";
        };
        Wayland = {
          CompositorCommand = "${pkgs.libsForQt5.kwin}/kwin_wayland --drm --no-lockscreen --no-global-shortcuts --locale1";
        };
      };
    };

    # Configure keymap in X11
    services.xserver.xkb.layout = "us";
    services.xserver.xkb.variant = "dvorak";
    services.xserver.xkb.options = "compose:prsc,caps:escape";

    # Enable CUPS to print documents.
    services.printing.enable = true;

    # Enable bluetooth
    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;
    systemd.user.services.mpris-proxy = {
      description = "Mpris proxy";
      after = ["network.target" "sound.target"];
      wantedBy = ["default.target"];
      serviceConfig.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
    };

    # Enable sound.
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    networking.nameservers = ["1.1.1.1" "1.0.0.1"];
    services.resolved = {
      enable = true;
      dnssec = "true";
      domains = ["~."];
      fallbackDns = ["1.1.1.1" "1.0.0.1"];
      dnsovertls = "true";
    };

    environment.systemPackages = with pkgs; [
      stablepkgs.systemd
      stablepkgs.dbus
      stablepkgs.sudo
      networkmanager-openvpn
      pipewire
      wireplumber
      curl
      btrfs-progs
      inotify-tools
      openssh
      ssh-agents
      rsync
      gnupg
      pinentry-curses
      pinentry-gtk2
      python3
      elvish
      carapace
      zsh
      git
      jujutsu
      libsForQt5.kwin
      kdePackages.sddm
      catppuccin-sddm-corners
      hyprland
      hyprlock
      hypridle
      hyprpaper
      hyprcursor
      waybar
      helix
      mpd
      eza
      dust
      bat
      ripgrep
      fzf
      ffmpeg_5
      mpv
      yt-dlp
      imagemagick
      dunst
      kitty
      kitty-img
      kitty-themes
      home-manager
      hunspell
      starship
      udisks
      udiskie
      wl-clipboard
      xclip
      clipman
    ];

    fonts.packages = with pkgs; [
      inconsolata
      dejavu_fonts
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      dina-font
      proggyfonts
      nerdfonts
    ];

    programs.zsh.enable = true;
    programs.ssh.startAgent = true;

    # Users
    security.sudo = {
      enable = true;
      execWheelOnly = true;
    };

    users.mutableUsers = false;

    users.users = {
      aftix = {
        isNormalUser = true;
        description = "aftix";
        extraGroups = ["networkmanager" "wheel"];
        shell = pkgs.zsh;
        uid = 1000;
        hashedPasswordFile = "/state/passwd.aftix";
        packages = with pkgs; [
          rustup
          go
          sccache
          firefox-bin
          ungoogled-chromium
          pipx
          conda
          pavucontrol
          mpc-cli
          pass
          xdotool
          vault
          gh
          element-desktop
          discord
          betterdiscordctl
          tofi
          slurp
          libnotify
          notify-desktop
          weechat-unwrapped
          weechatScripts.weechat-notify-send
          python312Packages.aria2p
        ];
      };
      root.hashedPasswordFile = "/state/passwd.root";
    };

    # This option defines the first version of NixOS you have installed on this particular machine,
    # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
    #
    # Most users should NEVER change this value after the initial install, for any reason,
    # even if you've upgraded your system to a new NixOS release.
    #
    # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
    # so changing it will NOT upgrade your system.
    #
    # This value being lower than the current NixOS release does NOT mean your system is
    # out of date, out of support, or vulnerable.
    #
    # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
    # and migrated your data accordingly.
    #
    # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
    system.stateVersion = "23.11"; # Did you read the comment?
  }
