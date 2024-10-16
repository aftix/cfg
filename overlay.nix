inputs: final: prev: {
  inherit (inputs.stablepkgs.legacyPackages.${final.system}) znc freshrss fail2ban transmission_4 hyprpaper xdg-desktop-portal-hyprland;

  carapace =
    (prev.carapace.overrideAttrs {
      src = inputs.carapace;
      vendorHash = "sha256-TvI7N2i/+JYs9X7V6I+vbInG4YZxPdHGgXkm9ee5FgQ=";
    })
    .override {buildGoModule = final.buildGo123Module;};

  heisenbridge = prev.heisenbridge.overridePythonAttrs (oldAttrs: rec {
    version = "1.15.0";
    src = final.fetchFromGitHub {
      owner = "hifi";
      repo = oldAttrs.pname;
      rev = "refs/tags/v${version}";
      sha256 = "sha256-4K6Sffu/yKHkcoNENbgpci2dbJVAH3vVkogcw/IYpnw=";
    };
  });

  inherit (inputs.attic.overlays.default final prev) attic-client;

  nginx_blocker = final.callPackage ./packages/nginx_blocker.nix {inherit (inputs) nginxBlacklist;};
  youtube-operational-api = final.callPackage ./packages/youtube_operational_api.nix {};

  nu_plugin_audio_hook = final.callPackage ./packages/nu_plugin_audio_hook.nix {};
  nu_plugin_compress = final.callPackage ./packages/nu_plugin_compress.nix {};
  nu_plugin_dbus = final.callPackage ./packages/nu_plugin_dbus.nix {};
  nu_plugin_desktop_notifications = final.callPackage ./packages/nu_plugin_desktop_notifications.nix {};
  nu_plugin_dns = final.callPackage ./packages/nu_plugin_dns.nix {};
  nu_plugin_endecode = final.callPackage ./packages/nu_plugin_endecode.nix {};
  nu_plugin_explore = final.callPackage ./packages/nu_plugin_explore.nix {};
  nu_plugin_port_scan = final.callPackage ./packages/nu_plugin_port_scan.nix {};
  nu_plugin_port_list = final.callPackage ./packages/nu_plugin_port_list.nix {};
  nu_plugin_semver = final.callPackage ./packages/nu_plugin_semver.nix {};
  nu_plugin_skim = final.callPackage ./packages/nu_plugin_skim.nix {};
  nu_plugin_strutils = final.callPackage ./packages/nu_plugin_strutils.nix {};
}
