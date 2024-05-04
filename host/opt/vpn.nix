{
  pkgs,
  lib,
  config,
  ...
}:
with pkgs.nur.repos.LuisChDev; {
  networking.firewall = {
    allowedTCPPorts = [443];
    allowedUDPPorts = [1194];
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
        ${pkgs.bash}/bin/bash -c '\
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

  users.users.aftix.extraGroups = lib.mkIf config.my.users.aftix.enable ["nordvpn"];
}
