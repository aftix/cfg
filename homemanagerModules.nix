# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  inputs ? (import ./.).inputs,
  pkgsCfg ? import ./nixpkgs-cfg.nix {inherit inputs;},
  myLib ? import ./lib.nix {inherit inputs pkgsCfg;},
  ...
}: let
  commonModules = [
    pkgsCfg
    inputs.nix-index-database.homeModules.nix-index
    {
      programs = {
        nix-index-database.comma.enable = true;
        command-not-found.enable = false;
      };
    }
    ({
      pkgs,
      lib,
      ...
    }: {
      options = import ./nixos-home-options.nix pkgs lib;
    })
  ];

  localModules = myLib.modulesFromDirectoryRecursive ./homemanagerModules;
  localModuleList = inputs.nixpkgs.lib.mapAttrsToList (name: inputs.nixpkgs.lib.id) localModules;
in
  {
    commonModules = {imports = commonModules;};
    default = {imports = commonModules ++ localModuleList;};
  }
  // (myLib.modulesFromDirectoryRecursive ./extraHomemanagerModules)
