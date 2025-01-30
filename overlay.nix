inputs: final: prev:
{
  inherit (inputs.attic.overlays.default final prev) attic attic-client attic-server;
  inherit (inputs) nginxBlacklist;

  carapace = prev.carapace.overrideAttrs {
    src = inputs.carapace;
    vendorHash = "sha256-kxd/bINrZxgEmgZ67KjTTfuIr9ekpd08s0/p0Sht5Ks=";
  };

  cinny-desktop = prev.cinny-desktop.overrideAttrs {
    postPatch = let
      inherit (final) pkgs lib;
      cinny' = assert lib.assertMsg (
        pkgs.cinny.version == prev.cinny-desktop.version
      ) "cinny.version (${pkgs.cinny.version}) != cinny-desktop.version (${prev.cinny-desktop.version})";
        pkgs.cinny.override {
          conf = {
            hashRouter.enabled = true;
          };
        };
    in ''
      substituteInPlace tauri.conf.json \
        --replace-fail '"distDir": "../cinny/dist",' '"distDir": "${cinny'}",'
      substituteInPlace tauri.conf.json \
        --replace-fail '"cd cinny && npm run build"' '""'
    '';
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

  nixt = prev.nixt.override {nix = final.nixVersions.nix_2_24;};
  nixd = prev.nixd.override {nix = final.nixVersions.nix_2_24;};

  freshrssExts = final.lib.attrsets.recurseIntoAttrs (final.callPackage ./legacyPackages/freshrss {});
}
// prev.lib.filesystem.packagesFromDirectoryRecursive {
  inherit (final) callPackage;
  directory = ./packages;
}
