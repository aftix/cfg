{lib, ...}: {
  virtualisation.docker = {
    autoPrune.enable = true;
    storageDriver = lib.mkDefault "btrfs";
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };
}
