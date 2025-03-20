{
  inputs ? import ./flake-compat/inputs.nix,
  extraSpecialArgs ? import ./extraSpecialArgs.nix inputs,
  ...
}:
inputs.self.lib.nixosConfigurationsFromDirectoryRecursive {
  directory = ./nixosConfigurations;
  dep-injects = inputs.self.lib.dependencyInjects {};
  inherit extraSpecialArgs;
}
