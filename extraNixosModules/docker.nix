{lib, ...}: {
  virtualisation.docker = {
    autoPrune.enable = true;
    storageDriver = lib.mkDefault "btrfs";
    rootless = {
      enable = true;
      setSocketVariable = true;
      daemon.settings.dns = ["10.64.0.1"];
    };
  };
}
