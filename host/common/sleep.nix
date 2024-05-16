{pkgs, ...}: {
  nixpkgs.overlays = [
    (final: _: {
      check-prevent-sleep = final.writeShellApplication {
        name = "check-prevent-sleep";
        runtimeInputs = with final; [findutils coreutils-full];
        text = ''
          mkdir -p /var/run/prevent-sleep.d
          chmod 0777 /var/run/prevent-sleep.d
          COUNT="$(find /var/run/prevent-sleep.d/ -type f | wc -l)"
          [ "$COUNT" = "0" ] || exit 1
        '';
      };

      setup-prevent-sleep = final.writeShellApplication {
        name = "setup-prevent-sleep";
        runtimeInputs = with final; [coreutils-full];
        text = ''
          mkdir -p /var/run/prevent-sleep.d || :
          chmod 0777 /var/run/prevent-sleep.d || :
        '';
      };
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
