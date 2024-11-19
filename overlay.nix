inputs: final: prev: {
  yubikey-manager = prev.yubikey-manager.override (prev: {
    python3Packages =
      prev.python3Packages
      // {
        pyscard = let
          stable =
            inputs.stablepkgs.legacyPackages.${final.system}.python312Packages.pyscard;
        in
          stable.override {inherit (prev.python3Packages) buildPythonPackage pytestCheckHook setuptools;};
      };
  });

  carapace = prev.carapace.overrideAttrs {
    src = inputs.carapace;
    vendorHash = "sha256-fJXTgltbeUPgjwQbNbsU0w1WRK0Xqi8LQ6BltqypKJ4=";
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

  barcodebuddy = final.callPackage ./packages/barcodebuddy.nix {};
  coffeepaste = final.callPackage ./packages/coffeepaste.nix {};

  freshrssExts = final.lib.attrsets.recurseIntoAttrs (final.callPackage ./packages/freshrss {});

  inherit (inputs.attic.overlays.default final prev) attic attic-client attic-server;

  nixt = prev.nixt.override {nix = final.nixVersions.nix_2_24;};
  nixd = prev.nixd.override {nix = final.nixVersions.nix_2_24;};

  nginx_blocker = final.callPackage ./packages/nginx_blocker.nix {inherit (inputs) nginxBlacklist;};
  youtube-operational-api = final.callPackage ./packages/youtube_operational_api/package.nix {};

  nu_plugin_audio_hook = final.callPackage ./packages/nu_plugin_audio_hook.nix {};
  nu_plugin_compress = final.callPackage ./packages/nu_plugin_compress.nix {};
  nu_plugin_desktop_notifications = final.callPackage ./packages/nu_plugin_desktop_notifications.nix {};
  nu_plugin_dns = final.callPackage ./packages/nu_plugin_dns.nix {};
  nu_plugin_endecode = final.callPackage ./packages/nu_plugin_endecode.nix {};
  nu_plugin_explore = final.callPackage ./packages/nu_plugin_explore.nix {};
  nu_plugin_port_scan = final.callPackage ./packages/nu_plugin_port_scan.nix {};
  nu_plugin_port_list = final.callPackage ./packages/nu_plugin_port_list.nix {};
  nu_plugin_semver = final.callPackage ./packages/nu_plugin_semver.nix {};
  nu_plugin_strutils = final.callPackage ./packages/nu_plugin_strutils.nix {};
}
