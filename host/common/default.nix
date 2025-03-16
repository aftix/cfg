{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkDefault mkForce;
  inherit (lib.options) mkOption mkEnableOption;
in {
  imports = [
    ./apparmor.nix
    ./channels.nix
    ./coffeepaste.nix
    ./hostBlacklist
    ./root.nix
    ./sleep.nix
    ./statics.nix
    ./swayosd.nix
    ./youtube_operational_api.nix
  ];

  options.my = {
    flake = mkOption {
      default = "/home/aftix/src/cfg";
      description = "Location of NixOS configuration flake";
    };

    users.aftix.enable = mkEnableOption "aftix";

    uefi = mkEnableOption "uefi";

    systemdCapabilities = mkOption {
      readOnly = false;
      default = builtins.map (s: "~CAP_" + s) [
        "SYS_TIME"
        "SYS_PACCT"
        "KILL"
        "WAKE_ALARM"
        "FOWNER"
        "IPC_OWNER"
        "BPF"
        "LINUX_IMMUTABLE"
        "IPC_LOCK"
        "SYS_MODULE"
        "SYS_TTY_CONFIG"
        "SYS_BOOT"
        "SYS_CHROOT"
        "BLOCK_SUSPEND"
        "LEASE"
        "FSETID"
        "SETFCAP"
        "SETPCAP"
        "SYS_PTRACE"
        "SYS_NICE"
        "SYS_RESOURCE"
        "NET_ADMIN"
        "CHOWN"
        "SETUID"
        "SETGID"
      ];
    };

    systemdHardening = mkOption {
      readOnly = true;
      default = {
        CapabilityBoundingSet =
          mkDefault config.my.systemdCapabilities;
        IPAddressAllow = mkDefault "localhost";
        IPAddressDeny = mkDefault "any";
        LockPersonality = mkDefault true;
        MemoryDenyWriteExecute = mkDefault true;
        NoNewPrivileges = mkDefault true;
        PrivateDevices = mkDefault true;
        PrivateTmp = mkDefault true;
        PrivateUsers = mkDefault true;
        ProtectHome = mkDefault "read-only";
        ProtectHostname = mkDefault true;
        ProtectKernelModules = mkDefault true;
        ProtectKernelTunables = mkDefault true;
        ProtectProc = mkDefault "invisible";
        ProtectSystem = mkDefault "strict";
        RemoveIPC = mkDefault true;
        RestrictNamespaces = mkDefault "";
        RestrictRealtime = mkDefault true;
        RestrictSUIDSGID = mkDefault true;
        SystemCallArchitectures = mkDefault "native";
        UMask = mkDefault "0027";
      };
    };

    hardenPHPFPM = mkOption {
      readOnly = true;
      default = {
        workdir,
        datadir,
      }: {
        WorkingDirectory = workdir;
        MemoryDenyWriteExecute = false;
        ReadWritePaths = [datadir "/run/phpfpm"];

        IPAddressAllow = mkDefault "localhost";
        IPAddressDeny = mkDefault "any";
        LockPersonality = mkDefault true;
        NoNewPrivileges = mkDefault true;
        ProcSubset = mkDefault "pid";
        ProtectHostname = mkDefault true;
        ProtectKernelModules = mkDefault true;
        ProtectKernelTunables = mkDefault true;
        ProtectProc = mkDefault "invisible";
        RemoveIPC = mkDefault true;
        RestrictNamespaces = mkDefault true;
        RestrictRealtime = mkDefault true;
        RestrictSUIDSGID = mkDefault true;
        SystemCallArchitectures = mkDefault "native";
        UMask = mkForce "0027";
      };
    };

    lib = mkOption {
      default = {};
      type = with lib.types; attrsOf anything;
    };
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
        accept-flake-config = false;
        use-xdg-base-directories = true;
        trusted-users = ["@wheel"];
      };

      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
        randomizedDelaySec = "30min";
      };

      optimise.automatic = true;
    };

    # Set the host-specific things in the nixd configuration
    my.development.nixdConfig.options = lib.mkIf ((config.my.flake or "") != "") {
      nixos.expr = "(builtins.getFlake \"${config.my.flake}\").nixosConfigurations.${config.networking.hostName}.options";
      home-manager.expr =
        /*
        nix
        */
        ''
          let
            flake = builtins.getFlake "${config.my.flake}";
            nixosCfg = flake.nixosConfigurations.${config.networking.hostName}.config;
            pkgs = import <nixpkgs> {};
            inherit (pkgs) lib;
            inherit (flake.extra) extraSpecialArgs nixosHomeOptions hmInjectNixosHomeOptions;
            mkHmCfg = flake.inputs.home-manager.lib.homeManagerConfiguration;
            nixosOpts = nixosHomeOptions lib;
            modules = nixosCfg.dep-inject.commonHmModules ++ [
              nixosOpts
              ({pkgs, ...}: { nix.package = pkgs.nix;})
              (hmInjectNixosHomeOptions nixosCfg)
              (import "${config.my.flake}/homeConfigurations/aftix.nix")
            ];
          in
            (mkHmCfg {
              inherit pkgs lib extraSpecialArgs modules;
            }).options
        '';
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

      plymouth = {
        enable = true;
        theme = "breeze";
      };

      initrd.systemd = {
        enable = true;
        storePaths = with pkgs; [kbd];
      };

      kernelPackages = pkgs.linuxPackages_latest;
      # Enable https://en.wikipedia.org/wiki/Magic_SysRq_key
      kernel.sysctl."kernel.sysrq" = 1;
    };

    security = {
      unprivilegedUsernsClone = lib.mkDefault true;

      pam.services.systemd-run0 = {
        setEnvironment = true;
        pamMount = false;
      };

      sudo = {
        enable = true;
        execWheelOnly = true;
        extraConfig = "Defaults lecture = never";
      };
    };

    systemd.services.nix-daemon.serviceConfig = {
      MemoryHigh = "75%";
      MemoryMax = "87.5%";
      MemorySwapMax = "75%";
    };

    documentation = {
      man = {
        enable = true;
        generateCaches = true;
      };

      nixos.enable = true;
    };

    programs = {
      fuse.userAllowOther = true;
      nix-ld.enable = true;
      zsh.enable = true;
    };

    services.nixos-cli = {
      enable = true;
      config.use_nvd = true;
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
