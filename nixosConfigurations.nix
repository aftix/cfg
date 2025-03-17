{
  inputs ? import ./flake-compat/inputs.nix,
  myLib ? import ./lib.nix inputs,
  extraSpecialArgs ? import ./extraSpecialArgs.nix inputs,
  ...
}:
myLib.nixosConfigurationsFromDirectoryRecursive {
  directory = ./nixosConfigurations;
  dep-injects = myLib.dependencyInjects {
    extraInject = {commonHmModules = inputs.self.homemanagerModules.commonModules;};
  };
  inherit extraSpecialArgs;
}
