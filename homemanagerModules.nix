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
    ({
      pkgs,
      lib,
      ...
    }: {
      imports = ["${inputs.sources.nixcord}/modules/hm"];
      _module.args.nixcordPkgs = let
        discordAvailable = lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.discord;
        docsSystems = [
          "x86_64-linux"
          "aarch64-darwin"
        ];

        docsArtifacts = import "${inputs.sources.nixcord}/docs" {
          inherit pkgs;
          inherit (pkgs) lib;
          inherit (inputs.sources.nixcord) revision;
        };
      in
        (pkgs.lib.optionalAttrs discordAvailable {
          discord = pkgs.callPackage "${inputs.sources.nixcord}/pkgs/discord" {};
          discord-ptb = pkgs.callPackage "${inputs.sources.nixcord}/pkgs/discord" {branch = "ptb";};
          discord-canary = pkgs.callPackage "${inputs.sources.nixcord}/pkgs/discord" {branch = "canary";};
          discord-development = pkgs.callPackage "${inputs.sources.nixcord}/pkgs/discord" {branch = "development";};
        })
        // (pkgs.lib.optionalAttrs (builtins.elem pkgs.stdenv.hostPlatform.system docsSystems) {
          docs =
            docsArtifacts.html;
        })
        // {
          vencord = pkgs.callPackage "${inputs.sources.nixcord}/pkgs/vencord.nix" {};
          vencord-unstable = pkgs.callPackage "${inputs.sources.nixcord}/pkgs/vencord.nix" {unstable = true;};
          equicord = pkgs.callPackage "${inputs.sources.nixcord}/pkgs/equicord.nix" {};
          generate = pkgs.callPackage "${inputs.sources.nixcord}/pkgs/generate-options.nix" {};
          docs-json = docsArtifacts.json;
        };
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
