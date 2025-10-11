# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkDefault mkEnableOption mkIf;
in {
  options.aftix.syncthing = mkEnableOption "syncthing";

  config = mkIf config.aftix.syncthing {
    environment.systemPackages = [pkgs.syncthing];

    networking.firewall = {
      checkReversePath = mkDefault false;
      allowedTCPPorts = [8384 22000];
      allowedUDPPorts = [22000 21027];
    };

    services.syncthing = {
      enable = true;
      overrideDevices = true;
      overrideFolders = true;

      user = mkDefault "aftix";
      dataDir = mkDefault "/home/aftix/Documents";
      configDir = mkDefault "/home/aftix/.local/share/syncthing";
    };
  };
}
