{
  upkgs,
  lib,
  ...
}: let
  inherit (lib) mkDefault;
in {
  environment.systemPackages = [upkgs.syncthing];

  networking.firewall = {
    checkReversePath = false;
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
