# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.options) mkOption;
in {
  options.aftix.mpris.enable = mkOption {default = true;};

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

    systemd.user.services.mpris-proxy = lib.mkIf config.aftix.mpris.enable {
      description = "Mpris proxy";
      after = ["network.target" "sound.target"];
      wantedBy = ["default.target"];
      serviceConfig.ExecStart = "${lib.getExe' pkgs.bluez "mpris-proxy"}";
    };
  };
}
