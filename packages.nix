{
  inputs,
  overlay ? (import ./overlay.nix inputs),
  pkgsCfg ? (import ./nixpkgs-cfg.nix inputs overlay),
  system ? builtins.currentSystem or "unknown-system",
}: let
  pkgs = import inputs.nixpkgs ({
      overlays = [
        inputs.nur.overlays.default
        (_: _: {inherit (inputs) nginxBlacklist;})
      ];
      inherit (pkgsCfg.nixpkgs) config;
    }
    // inputs.nixpkgs.lib.optionalAttrs (system != null) {inherit system;});
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
      matrix-synapse-unwrapped
      ;

    freshrssExts = pkgs.lib.attrsets.recurseIntoAttrs (pkgs.callPackage ./legacyPackages/freshrss {});
  }
