inputs: final: prev: {
  inherit (inputs.stablepkgs.legacyPackages.${final.system}) znc freshrss fail2ban transmission_4 hyprpaper xdg-desktop-portal-hyprland;

  carapace =
    (prev.carapace.overrideAttrs {
      src = inputs.carapace;
      vendorHash = "sha256-biJN+WjNK/Fjjd3+ihZcFCu75fup3g9R6lIa6qHco5I=";
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

  nu_plugin_audio_hook = final.callPackage ./packages/nu_plugin_audio_hook.nix {};
  nu_plugin_compress = final.callPackage ./packages/nu_plugin_compress.nix {};
  nu_plugin_dbus = final.callPackage ./packages/nu_plugin_dbus.nix {};
  nu_plugin_desktop_notifications = final.callPackage ./packages/nu_plugin_desktop_notifications.nix {};
  nu_plugin_dns = final.callPackage ./packages/nu_plugin_dns.nix {};
  nu_plugin_endecode = final.callPackage ./packages/nu_plugin_endecode.nix {};
  nu_plugin_explore = final.callPackage ./packages/nu_plugin_explore.nix {};
  nu_plugin_strutils = final.callPackage ./packages/nu_plugin_strutils.nix {};
  nu_plugin_port_scan = final.callPackage ./packages/nu_plugin_port_scan.nix {};
}
