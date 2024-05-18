{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib.options) mkOption mkEnableOption;
in {
  imports = [
    ./apparmor.nix
    ./channels.nix
    ./coffeepaste.nix
    ./nh.nix
    ./root.nix
    ./sleep.nix
  ];

  options.my = {
    flake = mkOption {
      default = "/home/aftix/src/cfg";
      description = "Location of NixOS configuration flake";
    };

    users.aftix.enable = mkEnableOption "aftix";

    uefi = mkEnableOption "uefi";
  };

  config = {
    environment = {
      systemPackages = with pkgs; [
        home-manager
        cachix

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

      pathsToLink = ["/share/zsh" "/share/bash-completion"];
    };

    nix = {
      nixPath = ["/nix/var/nix/profiles/per-user/root/channels"];

      settings = {
        experimental-features = ["nix-command" "flakes"];
        use-xdg-base-directories = true;

        substituters = [
          "https://nix-community.cachix.org"
          "https://cache.nixos.org"
          "https://cache.thalheim.io"
        ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc="
        ];
        trusted-users = ["@wheel"];
      };

      optimise.automatic = true;
    };

    # Use the systemd-boot EFI boot loader.
    boot = {
      loader = lib.mkIf config.my.uefi {
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
      zsh.enable = true;
    };

    users.mutableUsers = false;
    i18n = rec {
      defaultLocale = "en_US.UTF-8";
      extraLocaleSettings = {
        LC_ALL = "C.UTF-8";
        LANGUAGE = defaultLocale;
      };
    };
    console.font = "Lat2-Terminus16";
  };
}
