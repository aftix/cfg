{
  config,
  pkgs,
  ...
}: let
  inherit (config.dep-inject) inputs;

  patchedHosts2 =
    pkgs.runCommandLocal "hosts2-patched" {
    }
    ''
      sed '/^0.0.0.0 storage\.googleapis\.com$/ d' "${inputs.hostsBlacklist}/hosts/hosts2" > "$out"
    '';
in {
  networking.hostFiles = [
    "${inputs.hostsBlacklist}/hosts/hosts0"
    "${inputs.hostsBlacklist}/hosts/hosts1"
    "${patchedHosts2}"
    "${inputs.hostsBlacklist}/hosts/hosts3"
    ./personal-blacklist
  ];
}
