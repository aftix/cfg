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

    inherit (inputs.attic.packages.${final.hostPlatform.system}) attic attic-client attic-server;
    inherit (inputs) nginxBlacklist;

    carapace = prev.carapace.overrideAttrs {
      src = inputs.carapace;
      goSum = "${inputs.carapace}/go.sum";
      vendorHash = "sha256-mCa8jD4IXDoOn5jy2FWqMhb39mdhh5WsTHMNxQKAhkQ=";
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
