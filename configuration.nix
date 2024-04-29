{
  upkgs,
  nixpkgs,
  stablepkgs,
  home-manager,
  ...
}: let
  base = "/etc/nixpkgs/channels";
  nixpkgsPath = "${base}/nixpkgs";
  stablepkgsPath = "${base}/nixpkgs-23.11";
  homeManagerPath = "${base}/home-manager";
in {
  imports = [
    ./apparmor.nix
    ./backup.nix
    ./hardware-configuration.nix
    ./machine.nix
    ./user.nix
    ./network.nix
    ./sync.nix
  ];

  nix = {
    nixPath = [
      "nixpkgs=${nixpkgsPath}"
      "stablepkgs=${stablepkgsPath}"
      "home-manager=${homeManagerPath}"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];

    settings = {
      experimental-features = ["nix-command" "flakes"];
      substituters = ["https://hyprland.cachix.org"];
      trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
    };
  };

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        consoleMode = "auto";
        editor = false;
        memtest86.enable = true;
      };
    };

    kernelPackages = upkgs.linuxPackages_6_6_hardened;
    # Enable https://en.wikipedia.org/wiki/Magic_SysRq_key
    kernel.sysctl."kernel.sysrq" = 1;
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
        directories = [
          "/var/log"
          "/var/lib/bluetooth"
          "/var/lib/systemd/coredump"
          "/root/.config/rclone"
        ];
        files = [
          "/var/lib/cups/printers.conf"
          "/var/lib/cups/subscriptions.conf"
        ];
      };
    };

    systemPackages = with upkgs; [
      cachix
      nix-index

      catppuccin-sddm-corners
      kdePackages.kwin

      pigz
      lzip
      zstd
      pbzip2
      killall
      curl
      man-pages
      man-pages-posix

      btrfs-progs
      inotify-tools
      fuse
      usbutils

      openssh
      rsync
      gnupg

      python3

      helix
      moar
      eza
      dust
      ripgrep
      fzf
      starship
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

    nh = {
      enable = true;
      flake = "/home/aftix/src/cfg";
      clean = {
        enable = true;
        extraArgs = "--keep-since 7d --keep 10";
      };
    };

    zsh = {
      enable = true;
      interactiveShellInit = builtins.readFile ./_external/.zshrc;
    };

    nix-ld = {
      enable = true;
      libraries = [];
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

  services = {
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;

      theme = "catppuccin-sddm-corners";

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
          CompositorCommand = "kwin";
        };
        Theme.EnableAvatars = true;
      };
    };

    xserver = {
      # Configure keymap in X11
      xkb = {
        layout = "us";
        variant = "dvorak";
        options = "compose:prsc,caps:escape";
      };
    };

    # Enable CUPS to print documents.
    printing.enable = true;
    avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = true;
      openFirewall = true;
    };

    udisks2.enable = true;

    # Sound
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    clamav = {
      scanner.enable = true;
      updater.enable = true;
      fangfrisch.enable = true;
      daemon.enable = true;
    };
  };

  # Enable bluetooth
  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Experimental = true;
          KernelExperimental = true;
        };
      };
    };

    sane = {
      enable = true;
      extraBackends = with upkgs; [sane-airscan];
    };
  };

  systemd = {
    services.chown-config = {
      description = "set ownership of .config";
      wantedBy = ["default.target"];
      serviceConfig = {
        ExecStart = "${upkgs.coreutils}/bin/chown -R aftix:users /home/aftix/.config /home/aftix/.local/share/rustup /home/aftix/.local/share/go/pkg/mod/cache";
        Type = "oneshot";
      };
    };

    user.services.mpris-proxy = {
      description = "Mpris proxy";
      after = ["network.target" "sound.target"];
      wantedBy = ["default.target"];
      serviceConfig.ExecStart = "${upkgs.bluez}/bin/mpris-proxy";
    };

    tmpfiles.rules = [
      "L+ ${nixpkgsPath} - - - - ${nixpkgs}"
      "L+ ${stablepkgsPath} - - - - ${stablepkgs}"
      "L+ ${homeManagerPath} - - - - ${home-manager}"
    ];
  };

  security = {
    # Enable sound.
    rtkit.enable = true;
    # Enable user namespace cloning
    unprivilegedUsernsClone = true;
  };

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

  virtualisation.docker = {
    autoPrune.enable = true;
    storageDriver = "btrfs";
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
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
