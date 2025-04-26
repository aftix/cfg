{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.dep-inject) inputs;

  patchHost = {
    name,
    file,
  }: let
    removeCmds = lib.flip builtins.map config.my.blacklist.removeLines (regex: "sed -i'' -e '/${regex}/ d' \"$out\"");
  in
    pkgs.runCommandLocal name {
      src = file;
    }
    ''
      cp "$src" "$out"
      ${lib.strings.concatLines removeCmds}
    '';
in {
  options.my.blacklist.removeLines = lib.mkOption {
    default = [
      "^0.0.0.0 storage\\.googleapis\\.com$"
      "^0.0.0.0 addons\\.mozilla\\.org$"
    ];

    description = ''
      List of regexes that remove lines from the hosts blacklists on match.
    '';

    type = with lib.types; listOf str;
  };

  config.networking.hostFiles = builtins.map patchHost [
    {
      file = "${inputs.hostsBlacklist}/hosts/hosts0";
      name = "patched-hosts0";
    }
    {
      file = "${inputs.hostsBlacklist}/hosts/hosts1";
      name = "patched-hosts1";
    }
    {
      file = "${inputs.hostsBlacklist}/hosts/hosts2";
      name = "patched-hosts2";
    }
    {
      file = "${inputs.hostsBlacklist}/hosts/hosts3";
      name = "patched-hosts3";
    }
    {
      file = ./personal-blacklist;
      name = "patched-personal";
    }
  ];
}
