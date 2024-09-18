{config, ...}: let
  inherit (config.dep-inject) inputs;
in {
  networking.hostFiles = [
    "${inputs.hostsBlacklist}/hosts/hosts0"
    "${inputs.hostsBlacklist}/hosts/hosts1"
    "${inputs.hostsBlacklist}/hosts/hosts2"
    "${inputs.hostsBlacklist}/hosts/hosts3"
    ./personal-blacklist
  ];
}
