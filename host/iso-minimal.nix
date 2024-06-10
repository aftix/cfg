{
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [
    ./common
  ];

  users.users.root.hashedPasswordFile = null;

  boot.kernelPackages = lib.mkForce config.boot.zfs.package.latestCompatibleLinuxPackages;

  environment = {
    systemPackages = with pkgs; [
      btrfs-progs
    ];

    etc."nixos-custom" = {
      mode = "0755";
      source = ./.;
    };
  };

  console.keyMap = "dvorak";

  networking.hostName = "custom-install-iso-minimal";
}
