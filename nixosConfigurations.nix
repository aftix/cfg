# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
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
