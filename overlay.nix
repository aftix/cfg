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
    hydra = inputs.hydra.packages.${final.hostPlatform.system}.default;

    inherit (inputs.attic.packages.${final.hostPlatform.system}) attic attic-client attic-server;
    inherit (inputs) nginxBlacklist;

    carapace = prev.carapace.overrideAttrs {
      src = inputs.carapace;
      goSum = "${inputs.carapace}/go.sum";
      vendorHash = "sha256-oq1hZ2P093zsI+UAGHi5XfRXqGGxWpR5j7x7N7ng3xE=";
    };

    heisenbridge = prev.heisenbridge.overridePythonAttrs (oldAttrs: rec {
      version = "1.15.0";
      src = final.fetchFromGitHub {
        owner = "hifi";
        repo = oldAttrs.pname;
        rev = "refs/tags/v${version}";
        sha256 = "sha256-4K6Sffu/yKHkcoNENbgpci2dbJVAH3vVkogcw/IYpnw=";
      };
    });
  };
in
  {
    aftixLib = myLib;
    aftixPkgs = recurseIntoAttrs aftixPkgs;
    aftixOverlayedPkgs = recurseIntoAttrs aftixOverlayedPkgs;
  }
  // aftixPkgs
  // aftixOverlayedPkgs
