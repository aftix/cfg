inputs: final: prev: let
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
    lix = prev.lix.override {aws-sdk-cpp = null;};
    hydra = inputs.hydra.packages.${final.hostPlatform.system}.default;

    inherit (inputs.attic.packages.${final.hostPlatform.system}) attic attic-client attic-server;
    inherit (inputs) nginxBlacklist;

    carapace = prev.carapace.overrideAttrs {
      src = inputs.carapace;
      vendorHash = "sha256-+jOZ7EhMQZHvu4XToM7L1w2YCKCTOHKzZCOBsulLsH8=";
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
    aftixLib = inputs.self.lib;
    aftixPkgs = recurseIntoAttrs aftixPkgs;
    aftixOverlayedPkgs = recurseIntoAttrs aftixOverlayedPkgs;
  }
  // aftixPkgs
  // aftixOverlayedPkgs
