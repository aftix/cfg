{inputs, ...}: {
  entrypoint = ./configuration.nix;
  users = {
    aftix = import ../../homeConfigurations/aftix.nix;
    root = import ../../homeConfigurations/root.nix;
  };
  extraMods = [
    inputs.disko.nixosModules.disko
    inputs.lanzaboote.nixosModules.lanzaboote
  ];
}
