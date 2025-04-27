{
  inputs ? import ./inputs.nix,
  pkgsCfg ? import ./nixpkgs-cfg.nix {inherit inputs myLib;},
  myLib ? (import ./lib.nix {inherit inputs;}),
  ...
}: let
  nix-settings = let
    cfg = import ./nix-settings.nix;
  in {
    nix.settings = {inherit (cfg) substituters trusted-public-keys extra-experimental-features;};
  };

  commonModules = [
    pkgsCfg
    nix-settings
    ({
      lib,
      pkgs,
      ...
    }: {
      nix.package = lib.mkForce pkgs.nix;

      programs = {
        nix-index-database.comma.enable = true;
        command-not-found.enable = false;
      };
    })
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    inputs.nix-index-database.nixosModules.nix-index
    inputs.srvos.nixosModules.mixins-trusted-nix-caches
    inputs.preservation.nixosModules.default
    ({
      pkgs,
      lib,
      ...
    }: {
      options = import ./nixos-home-options.nix pkgs lib;
    })
  ];

  localModules = myLib.modulesFromDirectoryRecursive ./nixosModules;
  localModuleList = inputs.nixpkgs.lib.mapAttrsToList (name: inputs.nixpkgs.lib.id) localModules;
in
  {
    inherit nix-settings;
    inherit localModules;
    default = {imports = commonModules ++ localModuleList;};
  }
  // (myLib.modulesFromDirectoryRecursive ./extraNixosModules)
