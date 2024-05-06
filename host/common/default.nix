{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./apparmor.nix
    ./channels.nix
    ./network.nix
    ./nh.nix
    ./root.nix
  ];

  options.my = {
    flake = lib.options.mkOption {
      default = "/home/aftix/src/cfg";
      description = "Location of NixOS configuration flake";
    };

    users.aftix.enable = lib.options.mkEnableOption "aftix";
  };

  config = {
    environment.systemPackages = with pkgs; [
      home-manager

      killall
      curl
      man-pages
      man-pages-posix

      fuse
      inotify-tools
      usbutils

      openssh

      python3
    ];

    nix = {
      nixPath = ["/nix/var/nix/profiles/per-user/root/channels"];

      settings = {
        experimental-features = ["nix-command" "flakes"];
        use-xdg-base-directories = true;
      };

      optimise.automatic = true;
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

      # Use hardened linux
      kernelPackages = pkgs.linuxPackages_6_6_hardened;
      # Enable https://en.wikipedia.org/wiki/Magic_SysRq_key
      kernel.sysctl."kernel.sysrq" = 1;
    };

    security = {
      unprivilegedUsernsClone = lib.mkDefault true;

      sudo = {
        enable = true;
        execWheelOnly = true;
        extraConfig = "Defaults lecture = never";
      };
    };

    documentation.man = {
      enable = true;
      generateCaches = true;
    };

    programs = {
      fuse.userAllowOther = true;
      nix-ld.enable = true;
      zsh = {
        enable = true;
        interactiveShellInit = builtins.readFile ../../_external/.zshrc;
      };

      nix-index-database.comma.enable = true;
      command-not-found.enable = false;
    };

    users.mutableUsers = false;
    i18n.defaultLocale = "en_US.UTF-8";
    console.font = "Lat2-Terminus16";
  };
}
