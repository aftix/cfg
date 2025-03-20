{
  pkgs,
  lib,
  ...
}: let
  check-prevent-sleep = pkgs.writeShellApplication {
    name = "check-prevent-sleep";
    runtimeInputs = with pkgs; [findutils coreutils-full];
    text = ''
      mkdir -p /var/run/prevent-sleep.d
      chmod 0777 /var/run/prevent-sleep.d
      COUNT="$(find /var/run/prevent-sleep.d/ -type f | wc -l)"
      [ "$COUNT" = "0" ] || exit 1
    '';
  };

  setup-prevent-sleep = pkgs.writeShellApplication {
    name = "setup-prevent-sleep";
    runtimeInputs = with pkgs; [coreutils-full];
    text = ''
      mkdir -p /var/run/prevent-sleep.d || :
      chmod 0777 /var/run/prevent-sleep.d || :
    '';
  };
in {
  systemd.services = {
    prevent-sleep = {
      description = "Prevent system from sleeping";
      before = ["sleep.target"];
      requiredBy = ["sleep.target"];

      script = lib.getExe check-prevent-sleep;
      path = [pkgs.nix];
      serviceConfig.Type = "oneshot";
    };

    setup-prevent-sleep = {
      description = "Setup prevent-sleep.service";
      wantedBy = ["basic.target"];
      script = lib.getExe setup-prevent-sleep;

      path = [pkgs.nix];
      serviceConfig.Type = "oneshot";
    };
  };
}
