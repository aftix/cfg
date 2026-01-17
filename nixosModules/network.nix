# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  lib,
  config,
  ...
}: let
  cfg = config.aftix.network;
in {
  options.aftix.network = {
    enable = lib.mkEnableOption "network configuration";

    interfaces = lib.options.mkOption {
      default = [
        {
          interface = "enp6s0";
          name = "Wired LAN";
        }
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.network = {
      enable = true;

      networks = lib.mergeAttrsList (builtins.map (
          interface: {
            "10-${interface.interface}" = {
              name = interface.interface;
              dns = ["1.1.1.1" "1.0.0.1"];
              networkConfig = {
                Description = interface.name;
                DHCP = lib.mkDefault "yes";
                MulticastDNS = lib.mkDefault true;
                LinkLocalAddressing = lib.mkDefault "yes";
              };
            };
          }
        )
        cfg.interfaces);
    };

    networking.firewall = {
      enable = true;
      checkReversePath = lib.mkDefault false;
    };

    services.resolved = {
      enable = true;
      settings.Resolve = {
        FallbackDNS = ["1.1.1.1" "1.0.0.1"];
        Domains = ["~."];
        DNSOverTLS = "true";
      };
    };
  };
}
