# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  inputs ? import ./inputs.nix,
  myLib ? import ./lib.nix {inherit inputs;},
  pkgsCfg ? import ./nixpkgs-cfg.nix {inherit inputs myLib;},
  system ? builtins.currentSystem or "unknown-system",
  pkgs ? (import inputs.nixpkgs {
    inherit system;
    inherit (pkgsCfg.nixpkgs) config overlays;
  }),
  ...
}: let
  # SPDX-SnippetBegin
  # SPDX-SnippetComment: Taken from https://github.com/NixOS/nixpkgs/blob/374e6bcc403e02a35e07b650463c01a52b13a7c8/pkgs/top-level/release-lib.nix
  # SPDX-SnippetCopyrightText: (c) 2003-2025 Eelco Dolstra and the Nixpkgs/NixOS contributors
  # SPDX-License-Identifier: MIT
  recursiveMapPackages = f:
    pkgs.lib.mapAttrs (
      name: value:
        if pkgs.lib.isDerivation value
        then f value
        else if value.recurseForDerivations or false || value.recurseForRelease or false
        then recursiveMapPackages f value
        else []
    );
  # SPDX-SnippetEnd
in
  pkgs.aftixPkgs
  // pkgs.aftixOverlayedPkgs
