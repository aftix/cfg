{
  inputs ? import ./flake-compat/inputs.nix,
  overlay ? import ./overlay.nix inputs,
  pkgsCfg ? import ./nixpkgs-cfg.nix {inherit inputs overlay;},
  system ? builtins.currentSystem or "unknown-system",
  ...
}: let
  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [
      inputs.nur.overlays.default
      inputs.lix-module.overlays.default
      (_: _: {inherit (inputs) nginxBlacklist;})
    ];
    inherit (pkgsCfg.nixpkgs) config;
  };
  appliedOverlay = pkgs.extend overlay;
in
  pkgs.lib.filesystem.packagesFromDirectoryRecursive {
    inherit (pkgs) callPackage;
    directory = ./packages;
  }
  // {
    inherit
      (appliedOverlay)
      carapace
      heisenbridge
      attic
      attic-client
      attic-server
      lix
      hydra
      matrix-synapse-unwrapped
      ;

    freshrssExts = pkgs.lib.attrsets.recurseIntoAttrs (pkgs.callPackage ./legacyPackages/freshrss {});
  }
