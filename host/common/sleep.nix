{pkgs, ...}: {
  nixpkgs.overlays = [
    (_: prev: {
      check-prevent-sleep = prev.writeScriptBin "check-prevent-sleep" ''
        #!${prev.stdenv.shell}
        mkdir -p /var/run/prevent-sleep.d
        chmod 0777 /var/run/prevent-sleep.d
        COUNT="$(find /var/run/prevent-sleep.d/ -type f | wc -l)"
        [ "$COUNT" = "0" ] || exit 1
      '';

      setup-prevent-sleep = prev.writeScriptBin "setup-prevent-sleep" ''
        #!${prev.stdenv.shell}
        mkdir -p /var/run/prevent-sleep.d || :
        chmod 0777 /var/run/prevent-sleep.d || :
      '';
    })
  ];

  systemd.services = {
    prevent-sleep = {
      description = "Prevent system from sleeping";
      before = ["sleep.target"];
      requiredBy = ["sleep.target"];

      script = "${pkgs.check-prevent-sleep}/bin/check-prevent-sleep";
      path = [pkgs.nix];
      serviceConfig.Type = "oneshot";
    };

    setup-prevent-sleep = {
      description = "Setup prevent-sleep.service";
      wantedBy = ["basic.target"];
      script = "${pkgs.setup-prevent-sleep}/bin/setup-prevent-sleep";

      path = [pkgs.nix];
      serviceConfig.Type = "oneshot";
    };
  };
}
