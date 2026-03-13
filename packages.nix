# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  inputs ? import ./inputs.nix,
  myLib ? import ./lib.nix {inherit inputs;},
  pkgsCfg ? import ./nixpkgs-cfg.nix {inherit inputs myLib;},
  system ? builtins.currentSystem or "unknown-system",
  crossSystem ? null,
  pkgs ?
    import inputs.nixpkgs (
      inputs.nixpkgs.lib.recursiveUpdate {
        inherit system;
        inherit (pkgsCfg.nixpkgs) config overlays;
      }
      (inputs.nixpkgs.lib.optionalAttrs (crossSystem != null) {inherit crossSystem;})
    ),
  ...
}:
pkgs.aftixPkgs
// pkgs.aftixOverlayedPkgs
