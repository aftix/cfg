{ config, lib, pkgs, modulesPath, ... }:

{
  boot.initrd.kernelModules = [ "amdgpu" ];

  fileSystems."/".options = [ "noatime" "nodiratime" "discard=async" ];
  fileSystems."/persist".options = [ "noatime" "nodiratime" "discard=async" ];
  fileSystems."/nix".options = [ "noatime" "nodiratime" "discard=async" ];
  fileSystems."/home".options = [ "noatime" "nodiratime" "discard=async" ];
  fileSystems."/state".options = [ "noatime" "nodiratime" "discard=async" ];

  fileSystems."/persist".neededForBoot = true;
  fileSystems."/state".neededForBoot = true;

  # By default don't store state
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    mkdir /mnt
    mount -t btrfs -o subvolid=5 /dev/disk/by-label/nixos /mnt
    [ -e "/mnt/local/root/var/empty" ] && chattr -i /mnt/local/root/var/empty
    rm -rf /mnt/local/root
    btrfs subvolume snapshot /mnt/local/root@blank /mnt/local/root
    umount /mnt
    rmdir /mnt
  '';

  # Configure networking
  networking = {
    hostName = "hamilton";
    networkmanager.enable = true;
    interfaces = {
      enp6s0.ipv4.addresses = [{
        address = "192.168.1.179";
        prefixLength = 24;
      }];
    };
    defaultGateway = {
      address = "192.168.1.1";
      interface = "enp6s0";
    };
  };

  hardware.opengl.enable = true;
}
