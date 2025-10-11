# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  lib,
  config,
  ...
}: {
  options.aftix.docker = lib.mkEnableOption "docker configuration";

  config = lib.mkIf config.aftix.docker {
    virtualisation.docker = {
      autoPrune.enable = true;
      storageDriver = lib.mkDefault "btrfs";
      rootless = {
        enable = true;
        setSocketVariable = true;
        daemon.settings.dns = ["10.64.0.1"];
      };
    };
  };
}
