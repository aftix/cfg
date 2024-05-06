{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./common

    ./opt/display.nix
    ./opt/sound.nix
  ];

  users.users.root.hashedPasswordFile = null;

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

  services = {
    udisks2.enable = true;
    earlyoom.enable = true;
  };

  networking = {
    hostName = "custom-install-iso-minimal";
    wireless.enable = lib.mkForce false;
  };
}
