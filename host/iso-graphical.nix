{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkForce;
in {
  imports = [
    ./common

    ./opt/display.nix
    ./opt/sound.nix
  ];

  users.users.root.hashedPasswordFile = null;

  boot.kernelPackages = mkForce config.boot.zfs.package.latestCompatibleLinuxPackages;

  environment = {
    systemPackages = with pkgs; [
      btrfs-progs
    ];

    etc."nixos-custom" = {
      mode = "0755";
      source = ./.;
    };
  };

  systemd.oomd = {
    enableRootSlice = true;
    enableSystemSlice = true;
    enableUserSlices = true;
  };

  services = {
    udisks2.enable = true;

    greetd.settings = {
      initial_session.user = mkForce "nixos";
      default_session.user = mkForce "nixos";
    };
  };

  networking.hostName = "custom-install-iso";
}
