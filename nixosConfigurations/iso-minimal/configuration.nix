{
  pkgs,
  lib,
  ...
}: {
  users.users.root.hashedPasswordFile = null;

  boot = {
    kernelPackages = lib.mkForce pkgs.linuxPackages_6_6;
    initrd.systemd.enable = lib.mkForce false;
  };

  environment = {
    systemPackages = with pkgs; [
      btrfs-progs
    ];

    etc."nixos-custom" = {
      mode = "0755";
      source = ../..;
    };
  };

  console.keyMap = "dvorak";

  networking.hostName = "custom-install-iso-minimal";
}
