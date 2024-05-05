{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./common
  ];

  my.users.root.hashedPasswordFile = null;

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

  networking = {
    hostName = "custom-install-iso-minimal";
    wireless.enable = lib.mkForce false;
  };
}
