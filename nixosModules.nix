{
  inputs,
  overlay ? (import ./overlay.nix inputs),
  myLib ? (import ./lib.nix inputs),
  pkgsCfg ? (import ./nixpkgs-cfg.nix {inherit inputs myLib overlay;}),
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
    inputs.nixos-cli.nixosModules.nixos-cli
    inputs.preservation.nixosModules.default
    ({
      pkgs,
      lib,
      ...
    }: {
      options = import ./nixos-home-options.nix pkgs lib;
    })
  ];
in
  {
    inherit nix-settings;
    default = {imports = commonModules ++ [./host/common];};
  }
  // (myLib.modulesFromDirectoryRecursive ./host/opt)
