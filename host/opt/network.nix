{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.my.network;
in {
  options.my.network = {
    interfaces = lib.options.mkOption {
      default = [
        {
          interface = "enp6s0";
          name = "Wired LAN";
        }
      ];
    };
  };

  config = {
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

    networking = {
      networkmanager = {
        enable = lib.mkDefault true;
        unmanaged = lib.mkIf config.services.mullvad-vpn.enable ["wg0-mullvad"];
        plugins = lib.mkForce (with pkgs; [
          networkmanager-fortisslvpn
          networkmanager-iodine
          networkmanager-l2tp
          networkmanager-openvpn
          networkmanager-vpnc
          networkmanager-sstp
        ]);
      };
      firewall = {
        enable = true;
        checkReversePath = lib.mkDefault false;
      };
    };

    services.resolved = {
      enable = true;
      dnssec = "true";
      domains = ["~."];
      fallbackDns = ["1.1.1.1" "1.0.0.1"];
      dnsovertls = "true";
    };
  };
}
