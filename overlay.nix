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

  atticPkg = final.callPackage "${inputs.attic}/package.nix" {nix = final.nixVersions.nix_2_24;};
  aftixOverlayedPkgs = {
    hydra = inputs.hydra.packages.${final.hostPlatform.system}.default;

    attic = atticPkg;
    attic-server = (atticPkg.override {crates = ["attic-server"];}).overrideAttrs (oldAttrs: {
      meta = final.lib.recursiveUpdate (oldAttrs.meta or {}) {mainProgram = "atticd";};
    });
    attic-client = atticPkg.override {clientOnly = true;};

    inherit (inputs) nginxBlacklist;

    carapace = prev.carapace.overrideAttrs {
      src = inputs.carapace;
      goSum = "${inputs.carapace}/go.sum";
      vendorHash = "sha256-uroCoLMsqrbVAGlJnbKWT/tYO3o4NYrwh0KO7zClMq0=";
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
