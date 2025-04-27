{
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkDefault;
in {
  environment.systemPackages = [pkgs.syncthing];

  networking.firewall = {
    checkReversePath = mkDefault false;
    allowedTCPPorts = [8384 22000];
    allowedUDPPorts = [22000 21027];
  };

  services.syncthing = {
    enable = true;
    overrideDevices = true;
    overrideFolders = true;

    user = mkDefault "aftix";
    dataDir = mkDefault "/home/aftix/Documents";
    configDir = mkDefault "/home/aftix/.local/share/syncthing";
  };
}
