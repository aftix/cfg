{
  inputs ? import ./flake-compat/inputs.nix,
  overlay ? import ./overlay.nix inputs,
  pkgsCfg ? import ./nixpkgs-cfg.nix {inherit inputs overlay;},
  ...
}: let
  commonModules = [
    pkgsCfg
    inputs.nix-index-database.hmModules.nix-index
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
in
  {
    commonModules = {imports = commonModules;};
    default = {imports = commonModules ++ [./home/common];};
  }
  // (inputs.self.lib.modulesFromDirectoryRecursive ./home/opt)
