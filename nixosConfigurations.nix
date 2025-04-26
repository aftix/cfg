{
  inputs ? import ./inputs.nix,
  pkgsCfg ? null,
  myLib ? import ./lib.nix {inherit inputs pkgsCfg;},
  extraSpecialArgs ? import ./extraSpecialArgs.nix {inherit inputs;},
  ...
}:
myLib.nixosConfigurationsFromDirectoryRecursive {
  directory = ./nixosConfigurations;
  dep-injects = myLib.dependencyInjects {};
  inherit extraSpecialArgs;
}
