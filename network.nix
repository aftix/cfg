{upkgs, ...}:
with upkgs.nur.repos.LuisChDev; {
  systemd.network = {
    enable = true;

    networks."10-enp6s0" = {
      name = "enp6s0";
      dns = ["1.1.1.1" "1.0.0.1"];
      networkConfig = {
        Description = "Wired LAN";

        DHCP = "no";
        Address = ["192.168.1.179/24"];
        Gateway = "192.168.1.1";

        MulticastDNS = true;
        LinkLocalAddressing = "yes";
      };
    };
  };

  networking = {
    useDHCP = false;
    firewall = {
      enable = true;
      checkReversePath = false;
      allowedTCPPorts = [443 8384 22000];
      allowedUDPPorts = [1194 22000 21027];
    };
  };

  services.resolved = {
    enable = true;
    dnssec = "true";
    domains = ["~."];
    fallbackDns = ["1.1.1.1" "1.0.0.1"];
    dnsovertls = "true";
  };

  environment.systemPackages = [nordvpn];
  users.groups.nordvpn = {};
  systemd.services.nordvpnd = {
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    unitConfig = {
      Description = "NordVPN daemon";
      After = ["network-online.target"];
    };
    serviceConfig = {
      ExecStart = "${nordvpn}/bin/nordvpnd";
      ExecStartPre = ''
        ${upkgs.bash}/bin/bash -c '\
          mkdir -m 700 -p /var/lib/nordvpn; \
          if [ -z "$(ls -A /var/lib/nordvpn)" ]; then \
            cp -r ${nordvpn}/var/lib/nordvpn/* /var/lib/nordvpn; \
          fi'
      '';
      NonBlocking = true;
      KillMode = "process";
      Restart = "on-failure";
      RestartSec = 5;
      RuntimeDirectory = "nordvpn";
      RuntimeDirectoryMode = "0750";
      Group = "nordvpn";
    };
  };
  users.users.aftix.extraGroups = ["nordvpn"];
}
