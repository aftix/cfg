inputs: final: prev:
{
  aftixLib = inputs.self.lib;

  lix = prev.lix.override {aws-sdk-cpp = null;};

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

  freshrssExts = final.lib.attrsets.recurseIntoAttrs (final.callPackage ./legacyPackages/freshrss {});
}
// prev.lib.filesystem.packagesFromDirectoryRecursive {
  inherit (final) callPackage;
  directory = ./packages;
}
