{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf mkOverride mkForce;
  inherit (lib.attrsets) filterAttrs;
  inherit (lib.options) mkEnableOption mkOption;

  wwwCfg = config.my.www;
  cfg = config.my.www.rss;

  acmeHost =
    if cfg.acmeDomain == null
    then cfg.domain
    else cfg.acmeDomain;
in {
  options.my.www.rss = {
    enable = mkEnableOption "rss";

    domain = mkOption {
      type = lib.types.str;
    };

    acmeDomain = mkOption {
      default = wwwCfg.acmeDomain;
      type = with lib.types; nullOr str;
      description = "null to use \${my.www.rss.domain}";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets."freshrss_password" = {
      owner = "freshrss";
      group = "freshrss";
    };

    security.acme.certs =
      if (acmeHost != cfg.domain)
      then {
        ${acmeHost}.extraDomainNames = [
          "${cfg.domain}"
          "www.${cfg.domain}"
        ];
      }
      else {
        ${acmeHost} = {
          inherit (wwwCfg) group;
          extraDomainNames = ["www.${cfg.domain}"];
        };
      };

    systemd = {
      services = {
        freshrss-config.serviceConfig = {
          User = mkForce "freshrss";
          Group = mkForce "freshrss";
          WorkingDirectory = config.services.freshrss.package;
          StateDirectory = "freshrss";
          ReadWritePaths = mkForce ["/run/phpfpm"];

          PrivateNetwork = true;
          UMask = mkForce "0027";
        };

        phpfpm-freshrss.serviceConfig = filterAttrs (n: v: !builtins.elem n ["IPAddressAllow" "IPAddressDeny"]) (config.my.hardenPHPFPM {
          workdir = config.services.freshrss.package;
          datadir = "/var/lib/freshrss";
        });
      };

      tmpfiles.rules = [
        "d /var/lib/freshrss 0750 freshrss freshrss -"
        "Z /var/lib/freshrss 0750 freshrss freshrss -"
      ];
    };

    services = {
      phpfpm.pools.${config.services.freshrss.pool} = {
        user = mkForce "freshrss";
        group = mkForce "freshrss";
        settings = {
          "listen.owner" = mkForce "freshrss";
          "listen.group" = mkForce "freshrss";
          "listen.mode" = mkForce "0666";
        };
      };

      freshrss = {
        enable = true;

        user = "freshrss";

        extensions = with pkgs.freshrssExts; [
          official
          cntools
          latex
          reddit
          autottl
          links
          ezpriorities
          ezread
          threepane
        ];

        defaultUser = mkOverride 990 "aftix";
        passwordFile = mkOverride 990 config.sops.secrets."freshrss_password".path;
        baseUrl = mkOverride 990 "https://${cfg.domain}";
        virtualHost = cfg.domain;
        database = {
          user = mkOverride 990 null;
          host = mkOverride 990 null;
        };
      };

      nginx = {
        enable = true;

        virtualHosts.${cfg.domain} = {
          serverName = "${cfg.domain} www.${cfg.domain}";
          kTLS = true;
          forceSSL = true;
          useACMEHost = acmeHost;
          extraConfig = ''
            include /etc/nginx/bots.d/blockbots.conf;
            include /etc/nginx/bots.d/ddos.conf;
          '';
        };
      };

      youtube-operational-api = {
        enable = true;
        keysFile = config.sops.templates.youtubeapi_keys.path;
      };
    };

    users = {
      users.freshrss = {
        group = "freshrss";
        isSystemUser = true;
        shell = lib.getExe' pkgs.util-linux "nologin";
      };

      groups.freshrss = {};
    };
  };
}
