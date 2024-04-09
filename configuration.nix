{
  upkgs,
  spkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./machine.nix
    ./user.nix
    ./network.nix
  ];

  nix = {
    nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "nixos-config=/home/aftix/src/cfg/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
    settings.experimental-features = ["nix-command" "flakes"];
    gc = {
      automatic = true;
      persistent = true;
      dates = "daily";
      options = "--delete-older-than 30d";
    };
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot = {
      enable = true;
      consoleMode = "auto";
      editor = false;
      memtest86.enable = true;
    };
  };

  # Opt-in to state

  environment = {
    persistence = {
      # /persist is backed up (btrfs subvolume under safe/)
      "/persist" = {
        hideMounts = true;
        directories = ["/var/lib/nixos" "/etc/NetworkManager/system-connections" "/var/lib/nordvpn"];
      };
      # /state is not backup up (btrfs subvolume under local)
      "/state" = {
        hideMounts = true;
        directories = ["/var/log" "/var/lib/bluetooth" "/var/lib/systemd/coredump"];
      };
    };

    systemPackages = with upkgs; [
      spkgs.systemd
      spkgs.dbus
      spkgs.sudo

      pipewire
      wireplumber

      hyprland
      libsForQt5.kwin
      kdePackages.sddm
      catppuccin-sddm-corners

      pigz
      lzip
      zstd
      pbzip2
      curl
      mandoc
      man-pages
      man-pages-posix

      btrfs-progs
      inotify-tools
      fuse
      udisks

      openssh
      rsync
      gnupg

      python3

      helix
      eza
      dust
      bat
      ripgrep
      fzf
      starship
      zsh
    ];
  };

  documentation = {
    man = {
      generateCaches = true;
      man-db.enable = false;
      mandoc.enable = true;
    };
    dev.enable = true;
  };

  programs = {
    fuse.userAllowOther = true;
    hyprland.enable = true;
    zsh = {
      enable = true;
      interactiveShellInit = builtins.readFile ./_external/.zshrc;
    };
    nix-ld = {
      enable = true;
      libraries = with upkgs; [x264];
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
  services = {
    xserver = {
      enable = true;
      displayManager.sddm = {
        enable = true;
        wayland.enable = true;
        theme = "${upkgs.catppuccin-sddm-corners}";
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
            CompositorCommand = "${upkgs.libsForQt5.kwin}/kwin_wayland --drm --no-lockscreen --no-global-shortcuts --locale1";
          };
        };
      };

      # Configure keymap in X11
      xkb = {
        layout = "us";
        variant = "dvorak";
        options = "compose:prsc,caps:escape";
      };
    };

    # Enable CUPS to print documents.
    printing.enable = true;

    udisks2.enable = true;

    # Sound
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

  # Enable bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  systemd.user.services.mpris-proxy = {
    description = "Mpris proxy";
    after = ["network.target" "sound.target"];
    wantedBy = ["default.target"];
    serviceConfig.ExecStart = "${upkgs.bluez}/bin/mpris-proxy";
  };

  # Enable sound.
  security.rtkit.enable = true;

  fonts.packages = with upkgs; [
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
    font-awesome
    office-code-pro
    cantarell-fonts
  ];

  # Users
  security.sudo = {
    enable = true;
    execWheelOnly = true;
    extraConfig = "Defaults lecture = never";
  };

  users = {
    mutableUsers = false;
    users.root.hashedPasswordFile = "/state/passwd.root";
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
