inputs: final: prev:
{
  myLib = import ./lib.nix inputs final.lib;

  lix = prev.lix.override {aws-sdk-cpp = null;};

  inherit (inputs.attic.overlays.default final prev) attic attic-client attic-server;
  inherit (inputs) nginxBlacklist;

  carapace = prev.carapace.overrideAttrs {
    src = inputs.carapace;
    vendorHash = "sha256-9xrllVijAXwdAJH2tzF5Tgl2zFVn+SEIcyk1o4slYcE=";
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

  # From https://github.com/NixOS/nixpkgs/pull/389740
  # See https://nixpk.gs/pr-tracker.html?pr=389740 for when it lands
  pwvucontrol = let
    wireplumber_0_4_patched = final.wireplumber.overrideAttrs (attrs: rec {
      version = "0.4.17";
      src = final.fetchFromGitLab {
        domain = "gitlab.freedesktop.org";
        owner = "pipewire";
        repo = "wireplumber";
        tag = version;
        hash = "sha256-vhpQT67+849WV1SFthQdUeFnYe/okudTQJoL3y+wXwI=";
      };

      patches = [
        (final.fetchpatch {
          url = "https://gitlab.freedesktop.org/pipewire/wireplumber/-/commit/f4f495ee212c46611303dec9cd18996830d7f721.patch";
          hash = "sha256-dxVlXFGyNvWKZBrZniFatPPnK+38pFGig7LGAsc6Ydc=";
        })
      ];
    });
  in
    prev.pwvucontrol.overrideAttrs {
      buildInputs = with final; [
        cairo
        gdk-pixbuf
        glib
        gtk4
        libadwaita
        pango
        pipewire
        wireplumber_0_4_patched
      ];
    };
}
// prev.lib.filesystem.packagesFromDirectoryRecursive {
  inherit (final) callPackage;
  directory = ./packages;
}
