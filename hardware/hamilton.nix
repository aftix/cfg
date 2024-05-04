# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "usbhid" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-amd"];
  boot.extraModulePackages = [];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/6ba2e359-fab7-4fc2-b495-ff8a32fca218";
    fsType = "btrfs";
    options = ["subvol=local/root"];
  };

  fileSystems."/persist" = {
    device = "/dev/disk/by-uuid/6ba2e359-fab7-4fc2-b495-ff8a32fca218";
    fsType = "btrfs";
    options = ["subvol=safe/persist"];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/6ba2e359-fab7-4fc2-b495-ff8a32fca218";
    fsType = "btrfs";
    options = ["subvol=local/nix"];
  };

  fileSystems."/state" = {
    device = "/dev/disk/by-uuid/6ba2e359-fab7-4fc2-b495-ff8a32fca218";
    fsType = "btrfs";
    options = ["subvol=local/state"];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/6ba2e359-fab7-4fc2-b495-ff8a32fca218";
    fsType = "btrfs";
    options = ["subvol=safe/home"];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/6196-424C";
    fsType = "vfat";
    options = ["fmask=0022" "dmask=0022"];
  };

  fileSystems."/home/aftix/.cache" = {
    device = "/dev/disk/by-uuid/6ba2e359-fab7-4fc2-b495-ff8a32fca218";
    fsType = "btrfs";
    options = ["subvol=local/cache"];
  };

  fileSystems."/home/aftix/.config" = {
    device = "config";
    fsType = "tmpfs";
  };

  fileSystems."/home/aftix/.local/state" = {
    device = "/dev/disk/by-uuid/6ba2e359-fab7-4fc2-b495-ff8a32fca218";
    fsType = "btrfs";
    options = ["subvol=local/xdgstate"];
  };

  fileSystems."/home/aftix/media" = {
    device = "/dev/disk/by-uuid/3a27894c-d7d2-4bfa-a787-1e4e44c143d1";
    fsType = "btrfs";
    options = ["subvol=local/media"];
  };

  fileSystems."/home/aftix/.transmission" = {
    device = "/dev/disk/by-uuid/3a27894c-d7d2-4bfa-a787-1e4e44c143d1";
    fsType = "btrfs";
    options = ["subvol=local/transmission"];
  };

  swapDevices = [
    {device = "/dev/disk/by-uuid/2c0befe8-a1c3-40f8-80d7-730fa9fb311c";}
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp6s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.nordlynx.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
