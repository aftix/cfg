{
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf mkOverride mkForce;
  inherit (lib.options) mkOption;
  inherit (config.services.freshrss) enable;
  cfg = config.my.www;
in {
  options.my.www.rssSubdomain = mkOption {
    default = "rss";
    type = lib.types.str;
  };

  config = mkIf enable {
    sops.secrets."freshrss_password" = {
      inherit (config.my.www) group;
      owner = config.my.www.user;
    };

    security.acme.certs.${cfg.hostname}.extraDomainNames = [
      "${cfg.rssSubdomain}.${cfg.hostname}"
      "www.${cfg.rssSubdomain}.${cfg.hostname}"
    ];

    systemd.services.freshrss-config.serviceConfig = {
      User = mkForce cfg.user;
      Group = mkForce cfg.group;
    };

    services = {
      phpfpm.pools.${config.services.freshrss.pool} = {
        user = mkForce cfg.user;
        group = mkForce cfg.group;
        settings = {
          "listen.owner" = mkForce cfg.user;
          "listen.group" = mkForce cfg.group;
        };
      };

      freshrss = {
        inherit (cfg) user;

        defaultUser = mkOverride 990 "aftix";
        passwordFile = mkOverride 990 config.sops.secrets."freshrss_password".path;
        baseUrl = mkOverride 990 "https://${cfg.rssSubdomain}.${cfg.hostname}";
        virtualHost = "${cfg.rssSubdomain}.${cfg.hostname}";
        database = {
          user = mkOverride 990 null;
          host = mkOverride 990 null;
        };
      };

      nginx.virtualHosts."${cfg.rssSubdomain}.${cfg.hostname}" = {
        serverName = "${cfg.rssSubdomain}.${cfg.hostname} www.${cfg.rssSubdomain}.${cfg.hostname}";
        kTLS = true;
        forceSSL = true;
        useACMEHost = cfg.hostname;
      };
    };
  };
}
