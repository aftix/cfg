{upkgs, ...}: {
  environment.systemPackages = with upkgs; [
    syncthing
  ];

  networking.firewall = {
    checkReversePath = false;
    allowedTCPPorts = [8384 22000];
    allowedUDPPorts = [22000 21027];
  };

  services.syncthing = let
    home = "/home/aftix";
  in {
    enable = true;
    user = "aftix";
    dataDir = "${home}/Documents";
    configDir = "${home}/.local/share/syncthing";
    overrideDevices = true;
    overrideFolders = true;
  };
}
