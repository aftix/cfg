{
  config,
  upkgs,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./opt/backup.nix
  ];

  boot = {
    initrd = {
      availableKernelModules = ["nvme" "xhci_pci" "ahci" "usbhid" "sd_mod"];
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

    kernelModules = ["kvm-amd"];
    extraModulePackages = [];
  };

  services.xserver.videoDrivers = ["modesetting"];

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
  };
  systemd = {
    services.chown-config = {
      description = "set ownership of .config";
      wantedBy = ["default.target"];
      serviceConfig = {
        ExecStart = "${upkgs.coreutils}/bin/chown -R aftix:users /home/aftix/.config";
        Type = "oneshot";
      };
    };

    network.networks."10-enp6s0".networkConfig = {
      DHCP = lib.mkForce "no";
      Address = ["192.168.1.179/24"];
      Gateway = "192.168.1.1";
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/6ba2e359-fab7-4fc2-b495-ff8a32fca218";
      fsType = "btrfs";
      options = ["subvol=local/root" "noatime" "nodiratime" "discard=async"];
    };

    "/persist" = {
      device = "/dev/disk/by-uuid/6ba2e359-fab7-4fc2-b495-ff8a32fca218";
      fsType = "btrfs";
      neededForBoot = true;
      options = ["subvol=safe/persist" "noatime" "nodiratime" "discard=async"];
    };

    "/nix" = {
      device = "/dev/disk/by-uuid/6ba2e359-fab7-4fc2-b495-ff8a32fca218";
      fsType = "btrfs";
      options = ["subvol=local/nix" "noatime" "nodiratime" "discard=async"];
    };

    "/state" = {
      device = "/dev/disk/by-uuid/6ba2e359-fab7-4fc2-b495-ff8a32fca218";
      fsType = "btrfs";
      neededForBoot = true;
      options = ["subvol=local/state" "noatime" "nodiratime" "discard=async"];
    };

    "/home" = {
      device = "/dev/disk/by-uuid/6ba2e359-fab7-4fc2-b495-ff8a32fca218";
      fsType = "btrfs";
      options = ["subvol=safe/home" "noatime" "nodiratime" "discard=async"];
    };

    "/home/aftix/.config" = {
      device = "config";
      fsType = "tmpfs";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/6196-424C";
      fsType = "vfat";
    };

    "/home/aftix/.cache" = {
      device = "/dev/disk/by-uuid/6ba2e359-fab7-4fc2-b495-ff8a32fca218";
      fsType = "btrfs";
      options = ["subvol=local/cache" "noatime" "nodiratime" "nodev" "noexec" "nosuid" "discard=async"];
    };

    "/home/aftix/media" = {
      device = "/dev/disk/by-uuid/3a27894c-d7d2-4bfa-a787-1e4e44c143d1";
      fsType = "btrfs";
      options = ["subvol=local/media" "noatime" "nodiratime" "nodev" "noexec" "nosuid" "discard=async"];
    };

    "/home/aftix/.transmission" = {
      device = "/dev/disk/by-uuid/3a27894c-d7d2-4bfa-a787-1e4e44c143d1";
      fsType = "btrfs";
      options = ["subvol=local/transmission" "noatime" "nodiratime" "nodev" "noexec" "nosuid" "discard=async"];
    };

    "/home/aftix/.local/state" = {
      device = "/dev/disk/by-uuid/6ba2e359-fab7-4fc2-b495-ff8a32fca218";
      fsType = "btrfs";
      options = ["subvol=local/xdgstate" "noatime" "nodiratime" "discard=async"];
    };
  };

  swapDevices = [
    {device = "/dev/disk/by-uuid/2c0befe8-a1c3-40f8-80d7-730fa9fb311c";}
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Misc
  hardware.opengl.enable = true;
}
