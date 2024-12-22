{
  lib,
  config,
  ...
}: let
  inherit (lib.options) mkOption mkEnableOption;

  cfg = config.my.www;
  fullHostname = "${cfg.forgejo.subdomain}.${cfg.hostname}";
in {
  options.my.www.forgejo = {
    enable = mkEnableOption "forgejo";

    subdomain = mkOption {
      default = "forge";
      type = lib.types.str;
    };
  };

  config = lib.mkIf cfg.forgejo.enable {
    security.acme.certs.${cfg.hostname}.extraDomainNames = [
      "${fullHostname}"
      "www.${fullHostname}"
    ];

    services.nginx.virtualHosts.${fullHostname} = {
      serverName = "${fullHostname} www.${fullHostname}";
      kTLS = true;
      forceSSL = true;
      useACMEHost = cfg.hostname;
      extraConfig = ''
        include /etc/nginx/bots.d/blockbots.conf;
        include /etc/nginx/bots.d/ddos.conf;
      '';

      locations."/".tryFiles = "$uri $uri/ =404";
    };
  };
}
