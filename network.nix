{upkgs, ...}: let
  nordvpn = upkgs.nur.repos.LuisChDev.nordvpn;
in {
  networking = {
    nameservers = ["1.1.1.1" "1.0.0.1"];
    firewall = {
      checkReversePath = false;
      allowedTCPPorts = [443];
      allowedUDPPorts = [1194];
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