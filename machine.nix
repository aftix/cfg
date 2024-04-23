{lib, ...}: {
  boot = {
    initrd = {
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
  };

  fileSystems = {
    "/".options = ["noatime" "nodiratime" "discard=async"];
    "/persist".options = ["noatime" "nodiratime" "discard=async"];
    "/nix".options = ["noatime" "nodiratime" "discard=async"];
    "/home".options = ["noatime" "nodiratime" "discard=async"];
    "/state".options = ["noatime" "nodiratime" "discard=async"];

    "/persist".neededForBoot = true;
    "/state".neededForBoot = true;
  };

  # Configure networking
  networking = {
    hostName = "hamilton";
    networkmanager.enable = true;
    interfaces = {
      enp6s0.ipv4.addresses = [
        {
          address = "192.168.1.179";
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = {
      address = "192.168.1.1";
      interface = "enp6s0";
    };
  };

  # Misc
  hardware.opengl.enable = true;
}
