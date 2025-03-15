{inputs, ...}: {
  entrypoint = ./configuration.nix;
  users = {
    aftix = import ../../homeConfigurations/aftix-minimal.nix;
    root = import ../../homeConfigurations/root.nix;
  };
  extraMods = [
    inputs.srvos.nixosModules.server
    inputs.srvos.nixosModules.mixins-nginx
  ];
}
