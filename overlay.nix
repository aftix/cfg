# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  inputs ? import ./inputs.nix,
  myLib ? import ./lib.nix {inherit inputs;},
  ...
}: final: prev: let
  inherit (final.lib.attrsets) recurseIntoAttrs;

  aftixPkgs =
    (prev.lib.filesystem.packagesFromDirectoryRecursive {
      inherit (final) callPackage;
      directory = ./packages;
    })
    // {
      freshrssExts = recurseIntoAttrs (final.callPackage ./legacyPackages/freshrss {});
    };
  aftixOverlayedPkgs = {
    # hydra = inputs.hydra.packages.${final.hostPlatform.system}.default;

    inherit (inputs) nginxBlacklist;

    nixos-rebuild-ng = prev.nixos-rebuild-ng.override {
      nix = final.lixPackageSets.git.lix;
    };
  };
in
  {
    aftixLib = myLib;
    aftixPkgs = recurseIntoAttrs aftixPkgs;
    aftixOverlayedPkgs = recurseIntoAttrs aftixOverlayedPkgs;
  }
  // aftixPkgs
  // aftixOverlayedPkgs
