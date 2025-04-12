{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib.strings) optionalString;
in {
  imports = [
    ../../hardware/hamilton.nix
    ../../hardware/disko/hamilton.nix

    ../../host/opt/aftix.nix
    ../../host/opt/btrfs-snapshots
    ../../host/opt/bluetooth.nix
    ../../host/opt/cups.nix
    ../../host/opt/display.nix
    ../../host/opt/docker.nix
    ../../host/opt/hydra-substituter.nix
    ../../host/opt/network.nix
    ../../host/opt/silentboot.nix
    ../../host/opt/sound.nix
    ../../host/opt/syncthing.nix
  ];

  sops = {
    defaultSopsFile = ../../secrets/host/secrets.yaml;
    age.keyFile = "/home/aftix/.local/persist/home/aftix/.config/sops/age/keys.txt";

    secrets = {
      gh_access_token = {};
      restic_hamilton_password = {};
      restic_hamilton_aws_id = {};
      restic_hamilton_aws_secret = {};

      hydra_store_bucket = {
        sopsFile = ../../secrets/host/srv_secrets.yaml;
      };
      hydra_store_url = {
        sopsFile = ../../secrets/host/srv_secrets.yaml;
      };
      hydra_store_key_id = {
        sopsFile = ../../secrets/host/srv_secrets.yaml;
      };
      hydra_store_token = {
        sopsFile = ../../secrets/host/srv_secrets.yaml;
      };
      hydra_store_secret_key = {
        sopsFile = ../../secrets/host/srv_secrets.yaml;
      };
      hydra_store_public_key = {
        sopsFile = ../../secrets/host/srv_secrets.yaml;
        mode = "0444";
      };
    };

    templates = {
      nixAccessTokens = {
        mode = "0444";
        content = ''
          extra-access-tokens = github.com=${config.sops.placeholder.gh_access_token}
        '';
      };

      hydraStore = {
        mode = "0400";
        content = ''
          AWS_ACCESS_KEY_ID=${config.sops.placeholder.hydra_store_key_id}
          AWS_SECRET_ACCESS_KEY=${config.sops.placeholder.hydra_store_token}
        '';
      };

      restic = {
        mode = "0400";
        content = ''
          AWS_ACCESS_KEY_ID=${config.sops.placeholder.restic_hamilton_aws_id}
          AWS_SECRET_ACCESS_KEY=${config.sops.placeholder.restic_hamilton_aws_secret}
        '';
      };
    };
  };

  my = {
    disko = {
      rootDrive = {
        name = "nvme0n1";
        mountOptions = ["discard=async" "nosuid" "relatime" "nodiratime"];

        xdgSubvolumeUsers = ["aftix"];
      };

      massDrive = {
        name = "sda";

        subvolumes = [
          {
            name = "media";
            mountpoint = "/home/aftix/media";
          }
          {
            name = "transmission";
            mountpoint = "/home/aftix/.transmission";
          }
        ];
      };
    };

    greeterCfgExtra = ''
      monitor=desc:ASUSTek COMPUTER INC ASUS VG27W 0x0001995C,preferred,0x0,1
      monitor=desc:ViewSonic Corporation VX2703 SERIES T8G132800478,preferred,2560x-180,1,transform,1
    '';

    swayosd.enable = true;

    uefi = true;
  };

  nix.extraOptions = ''
    !include ${config.sops.templates.nixAccessTokens.path}
  '';

  environment = {
    systemPackages = with pkgs; [
      btrfs-progs

      pam_u2f
      yubico-pam
      yubikey-personalization
      yubikey-manager

      sbctl
    ];
  };

  # opt into state
  preservation = {
    enable = true;
    preserveAt = {
      # /persist is backed up (btrfs subvolume under safe/)
      "/persist" = {
        commonMountOptions = ["x-gvfs-hide"];
        directories = [
          "/var/lib/nixos"
          "/etc/mullvad-vpn"
          "/etc/secureboot"
          "/var/cache/mullvad-vpn"
        ];
        files = [
          {
            file = "/etc/machine-id";
            inInitrd = true;
            how = "symlink";
          }
          {
            file = "/var/lib/systemd/random-seed";
            inInitrd = true;
            how = "symlink";
          }
        ];
      };
      # /state is not backup up (btrfs subvolume under local)
      "/state" = {
        commonMountOptions = ["x-gvfs-hide"];
        directories = [
          {
            directory = "/var/log";
            inInitrd = true;
          }
          "/var/lib/bluetooth"
          "/var/lib/systemd/coredump"
          "/var/lib/systemd/timers"
        ];
        files = [
          "/var/lib/cups/printers.conf"
          "/var/lib/cups/subscriptions.conf"
        ];
      };
    };
  };

  security.pam.services = {
    greetd.u2fAuth = true;
    login.u2fAuth = true;
    polkit-1.u2fAuth = true;
    su.u2fAuth = true;
    swaylock.u2fAuth = true;
  };

  networking = {
    hostName = "hamilton";
    useDHCP = false;
  };

  systemd = {
    network.networks."10-enp6s0".networkConfig = {
      DHCP = lib.mkForce "no";
      Address = ["192.168.1.179/24"];
      Gateway = "192.168.1.1";
    };

    oomd.enableUserSlices = true;

    services = {
      nix-daemon.serviceConfig.CPUQuota = "2100%";

      systemd-machine-id-commit = {
        unitConfig.ConditionPathIsMountPoint = [
          ""
          "/persist/etc/machine-id"
        ];
        serviceConfig.ExecStart = [
          ""
          "systemd-machine-id-setup --commit --root /persist"
        ];
      };
    };
  };

  documentation.dev.enable = true;
  time.timeZone = "America/Chicago";

  services = {
    bpftune.enable = true;
    mullvad-vpn.enable = true;

    pipewire.wireplumber.configPackages = let
      genLua = {
        monitor ? "alsa",
        type ? "node",
        name,
        description ? "",
        nick ? "",
        disabled ? false,
      }: ''
        monitor.${monitor}.rules = [
          matches = [
            {
              ${type}.name = "${name}"
            }
          ]
          actions = {
            update-props = {
              ${optionalString (nick != "") (type + ".nick = \"${nick}\"")}
              ${optionalString (description != "") (type + ".description = \"${description}\"")}
              ${optionalString disabled (type + ".disabled = true")}
            }
          }
        ]
      '';

      writeConf = name: attrs: pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/${name}.conf" (genLua attrs);
    in [
      (writeConf "51-navi-disable" {
        type = "device";
        name = "alsa_card.pci-0000_0c_00.1";
        disabled = true;
      })

      (writeConf "52-starship-rename" {
        type = "device";
        name = "alsa_card.pci-0000_0e_00.4";
        description = "Built-in Audio";
        nick = "built-in";
      })

      (writeConf "53-soundcore-nick" {
        monitor = "bluez5";
        type = "device";
        name = "bluez_card.E8_EE_CC_3A_C5_87";
        nick = "headphones";
      })

      (writeConf "54-navi-device-disable" {
        name = "alsa_output.pci-0000_0c_00.1.hdmi-stereo-extra2";
        disabled = true;
      })

      (writeConf "55-starship-jack-rename" {
        name = "alsa_output.pci-0000_0e_00.4.iec958-stereo";
        description = "Built-in Audio Output";
        nick = "built-in output";
      })

      (writeConf "56-starship-mic-rename" {
        name = "alsa_input.pci-0000_0e_00.4.analog-stereo";
        description = "Built-in Audio Input";
        nick = "built-in input";
      })

      (writeConf "57-soundcore-node-nick" {
        name = "bluez_output.E8_EE_CC_3A_C5_87.1";
        nick = "headphones";
      })

      (writeConf "58-soundcore-input-disable" {
        name = "bluez_input.E8:EE:CC:3A:C5:87";
        disabled = true;
      })
    ];

    pcscd.enable = true;
    udisks2.enable = true;
    udev.packages = with pkgs; [yubikey-personalization android-udev-rules];
    xserver.videoDrivers = ["modesetting"];
  };

  services.restic.backups.backblaze = {
    backupPrepareCommand = lib.getExe (pkgs.writeNushellApplication {
      name = "get-restic-paths";
      runtimeInputs = [pkgs.util-linux];
      text =
        /*
        nu
        */
        ''
          $nu.pid | save -f /var/run/backupdisk.pid
          mkdir /restic-backblaze-backup /var/run /var/run/restic-backups-backblaze
          mount -t btrfs -o subvolid=5 ${config.my.backup.localSnapshotDrive} /restic-backblaze-backup
        '';
    });
    backupCleanupCommand = lib.getExe (pkgs.writeShellApplication {
      name = "cleanup-restic-backup";
      runtimeInputs = [pkgs.util-linux];
      text = ''
        umount /restic-backblaze-backup
        rmdir /restic-backblaze-backup || :
        rm /var/run/restic-backblaze-backup-files || :
        rm /var/run/backupdisk.pid || :
      '';
    });

    paths = ["/restic-backblaze-backup/${config.my.backup.snapshotPrefix}"];
    exclude = ["/restic-backblaze-backup/${config.my.backup.snapshotPrefix}/*.[0-9]*-[0-9]*-[0-9]*"];

    environmentFile = config.sops.templates.restic.path;
    passwordFile = config.sops.secrets.restic_hamilton_password.path;
    repository = "s3:s3.us-east-005.backblazeb2.com/aftix-hamilton-restic";
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
    inhibitsSleep = true;
    initialize = true;
    pruneOpts = ["--keep-last 156"];
    checkOpts = ["--with-cache"];
  };
  systemd.services.restic-backups-backblaze.after = ["btrfs-snapshots.service"];

  # Hardware specific settings

  boot = {
    loader.systemd-boot.enable = lib.mkForce false;
    lanzaboote = {
      enable = true;
      pkiBundle = "/persist/etc/secureboot";
    };

    initrd.systemd = rec {
      storePaths = with pkgs; [
        toybox
        btrfs-progs
      ];

      # By default don't store state
      services.reset-fs-state = {
        description = "Rollback BtrFS local/root subvolume to blank state";
        wantedBy = ["initrd.target"];
        after = ["basic.target"];
        before = ["sysroot.mount"];

        path = storePaths;

        unitConfig.DefaultDependencies = "no";
        serviceConfig.Type = "oneshot";

        script = ''
          MDIR="$(mktemp -d)"
          mount -t btrfs -o subvolid=5 /dev/disk/by-label/nixos "$MDIR"
          [ -e "$MDIR/local/root/var/empty" ] && chattr -i "$MDIR/local/root/var/empty"
          rm -rf "$MDIR/local/root"
          btrfs subvolume snapshot "$MDIR/local/root@blank" "$MDIR/local/root"
          umount "$MDIR"
          rmdir "$MDIR"
        '';
      };
    };
  };

  fileSystems = {
    "/persist".neededForBoot = true;
    "/state".neededForBoot = true;
    "/home".neededForBoot = true;
  };

  virtualisation.libvirtd.enable = true;

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
