# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.aftix.bluetooth = {
    enable = lib.mkEnableOption "bluetooth configuration";

    mpris = lib.mkOption {
      default = true;
      example = false;
      description = "whether to enable mpris proxy support";
      type = lib.types.bool;
    };
  };

  config = lib.mkIf config.aftix.bluetooth.enable {
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

    systemd.user.services.mpris-proxy = lib.mkIf config.aftix.bluetooth.mpris {
      description = "Mpris proxy";
      after = ["network.target" "sound.target"];
      wantedBy = ["default.target"];
      serviceConfig.ExecStart = "${lib.getExe' pkgs.bluez "mpris-proxy"}";
    };
  };
}
