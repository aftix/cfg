{
  config,
  lib,
  upkgs,
  ...
}: let
  inherit (lib.options) mkOption;
in {
  options.my.mpris.enable = mkOption {default = true;};

  config = {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Experimental = true;
          KernelExperimental = true;
        };
      };
    };

    systemd.user.services.mpris-proxy = lib.mkIf config.my.mpris.enable {
      description = "Mpris proxy";
      after = ["network.target" "sound.target"];
      wantedBy = ["default.target"];
      serviceConfig.ExecStart = "${upkgs.bluez}/bin/mpris-proxy";
    };
  };
}
