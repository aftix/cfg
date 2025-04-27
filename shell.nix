# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  system ? builtins.currentSystem or "unknown-system",
  crossSystem ? null,
  inputs ? import ./inputs.nix,
  myLib ? import ./lib.nix {inherit inputs;},
  pkgsCfg ? import ./nixpkgs-cfg.nix {inherit inputs myLib;},
}: let
  inherit (inputs.nixpkgs) lib;

  pkgs = import inputs.nixpkgs (
    lib.recursiveUpdate {
      inherit system;
      inherit (pkgsCfg.nixpkgs) overlays config;
    } (lib.optionalAttrs (crossSystem != null) {inherit crossSystem;})
  );
in
  pkgs.mkShell {
    name = "cfg-dev-shell";

    buildInputs = [
      pkgs.alejandra
      pkgs.just
      pkgs.nix-output-monitor
      pkgs.reuse
    ];
  }
