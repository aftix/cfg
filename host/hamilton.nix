{
  pkgs,
  lib,
  ...
}: let
  inherit (lib.strings) optionalString;
in {
  imports = [
    ../hardware/hamilton.nix
    ../hardware/disko/hamilton.nix
    ./common

    ./opt/aftix.nix
    ./opt/backup.nix
    ./opt/bluetooth.nix
    ./opt/clamav.nix
    ./opt/cups.nix
    ./opt/display.nix
    ./opt/docker.nix
    ./opt/network.nix
    ./opt/sound.nix
    ./opt/syncthing.nix
  ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/home/aftix/.local/persist/.config/sops/age/keys.txt";
  };

  my = {
    disko = {
      rootDrive = {
        name = "nvme0n1";
        mountOptions = ["discard=async"];

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

    backup.bucket = "aftix-hamilton-backup";
    uefi = true;

    greeterCfgExtra = ''
      monitor=desc:ASUSTek COMPUTER INC ASUS VG27W 0x0001995C,preferred,0x0,1
      monitor=desc:ViewSonic Corporation VX2703 SERIES T8G132800478,preferred,2560x-180,1,transform,1
    '';
  };

  environment = {
    systemPackages = with pkgs; [
      btrfs-progs

      pam_u2f
      yubico-pam
      yubikey-personalization
      yubikey-manager
    ];

    # opt into state
    persistence = {
      # /persist is backed up (btrfs subvolume under safe/)
      "/persist" = {
        hideMounts = true;
        directories = [
          "/var/lib/nixos"
          "/etc/NetworkManager/system-connections"
          "/etc/mullvad-vpn"
          "/var/cache/mullvad-vpn"
        ];
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
  };

  security.pam.services = {
    greetd.u2fAuth = true;
    login.u2fAuth = true;
    su.u2fAuth = true;
    sudo.u2fAuth = true;
    swaylock.u2fAuth = true;
  };

  systemd.network.networks."10-enp6s0".networkConfig = {
    DHCP = lib.mkForce "no";
    Address = ["192.168.1.179/24"];
    Gateway = "192.168.1.1";
  };
  networking = {
    hostName = "hamilton";
    useDHCP = false;
  };

  documentation.dev.enable = true;
  time.timeZone = "America/Chicago";

  systemd.oomd = {
    enableRootSlice = true;
    enableSystemSlice = true;
    enableUserSlices = true;
  };

  services = {
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

    udisks2.enable = true;
    udev.packages = [pkgs.yubikey-personalization];
    xserver.videoDrivers = ["modesetting"];
  };

  # Hardware specific settings
  hardware.opengl.enable = true;

  boot.initrd = {
    kernelModules = ["amdgpu"];

    # By default don't store state
    postDeviceCommands = lib.mkAfter ''
      mkdir /mnt
      mount -t btrfs -o subvolid=5 /dev/disk/by-label/nixos /mnt
      [ -e "/mnt/local/root/var/empty" ] && chattr -i /mnt/local/root/var/empty
      rm -rf /mnt/local/root
      btrfs subvolume snapshot /mnt/local/root@blank /mnt/local/root
      umount /mnt
      rmdir /mnt
    '';
  };

  fileSystems = {
    "/persist".neededForBoot = true;
    "/state".neededForBoot = true;
    "/home".neededForBoot = true;
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
