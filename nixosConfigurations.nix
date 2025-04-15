{inputs ? (import ./.).inputs, ...}:
inputs.self.lib.nixosConfigurationsFromDirectoryRecursive {
  directory = ./nixosConfigurations;
  dep-injects = inputs.self.lib.dependencyInjects {};
  inherit (inputs.self.extra) extraSpecialArgs;
}
