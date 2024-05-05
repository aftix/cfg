{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../hardware/hamilton.nix
    ../hardware/disko/hamilton.nix
    ../hardware/opt/backup.nix
    ./common

    ./opt/aftix.nix
    ./opt/bluetooth.nix
    ./opt/clamav.nix
    ./opt/cups.nix
    ./opt/display.nix
    ./opt/docker.nix
    ./opt/sound.nix
    ./opt/syncthing.nix
    ./opt/vpn.nix
  ];

  my.disko = {
    rootDrive = {
      name = "nvme0n1";
      mountOptions = ["discard=async" "relatime" "nodiratime"];

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

  environment = {
    systemPackages = with pkgs; [
      btrfs-progs
    ];

    # opt into state
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

  services = {
    udisks2.enable = true;
    earlyoom.enable = true;
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
