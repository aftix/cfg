{
  lib,
  config,
  ...
}: let
  inherit (lib.options) mkOption mkEnableOption;

  wwwCfg = config.my.www;
  cfg = config.my.www.forgejo;
  serviceCfg = config.services.forgejo;

  acmeHost =
    if cfg.acmeDomain == null
    then cfg.domain
    else cfg.acmeDomain;
in {
  options.my.www.forgejo = {
    enable = mkEnableOption "forgejo";

    domain = mkOption {
      type = lib.types.str;
    };

    acmeDomain = mkOption {
      default = wwwCfg.acmeDomain;
      type = with lib.types; nullOr str;
      description = "null to use \${my.www.forgejo.domain}";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      forgejo_from_addr = {
        owner = serviceCfg.user;
        inherit (serviceCfg) group;
      };
      forgejo_smtp_addr = {
        owner = serviceCfg.user;
        inherit (serviceCfg) group;
      };
      forgejo_smtp_port = {
        owner = serviceCfg.user;
        inherit (serviceCfg) group;
      };
      forgejo_smtp_user = {
        owner = serviceCfg.user;
        inherit (serviceCfg) group;
      };
      forgejo_smtp_password = {
        owner = serviceCfg.user;
        inherit (serviceCfg) group;
      };
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

    services = {
      openssh.settings = {
        AcceptEnv = "GIT_PROTOCOL";

        AllowUsers =
          lib.lists.optionals
          (!serviceCfg.settings.server.DISABLE_SSH)
          [serviceCfg.user];
      };

      nginx = {
        enable = true;

        upstreams.forgejo = {
          servers."unix:${serviceCfg.settings.server.HTTP_ADDR}" = {};
          extraConfig = ''
            keepalive 8;
          '';
        };

        virtualHosts.${cfg.domain} = {
          serverName = "${cfg.domain} www.${cfg.domain}";
          kTLS = true;
          forceSSL = true;
          useACMEHost = acmeHost;
          extraConfig = ''
            include /etc/nginx/bots.d/blockbots.conf;
            include /etc/nginx/bots.d/ddos.conf;
          '';

          locations."/" = {
            proxyPass = "http://forgejo/";
            extraConfig = ''
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;

              client_max_body_size 512M;
            '';
          };
        };
      };

      forgejo = {
        enable = true;
        secrets.mailer = {
          FROM = config.sops.secrets.forgejo_from_addr.path;
          SMTP_ADDR = config.sops.secrets.forgejo_smtp_addr.path;
          SMTP_PORT = config.sops.secrets.forgejo_smtp_port.path;
          USER = config.sops.secrets.forgejo_smtp_user.path;
          PASSWD = config.sops.secrets.forgejo_smtp_password.path;
        };
        settings = {
          DEFAULT = {
            APP_NAME = "aftforge";
            APP_SLOGAN = "Bespoke artisinal software";
          };

          admin.SEND_NOTIFICATION_EMAIL_ON_NEW_USER = true;

          cache = {
            ADAPTER = "twoqueue";
            HOST = builtins.toJSON {
              size = 100;
              recent_ratio = 0.25;
              ghost_ratio = 0.5;
            };
          };

          database.SQLITE_JOURNAL_MODE = "WAL";

          mailer = {
            ENABLED = true;
            PROTOCOL = "smtps";
          };
          security.LOGIN_REMEMBER_DAYS = 90;
          service = {
            DISABLE_REGISTRATION = true;
            REGISTER_EMAIL_CONFIRM = true;
            ENABLE_NOTIFY_MAIL = true;
          };
          server = {
            DOMAIN = cfg.domain;
            PROTOCOL = "http+unix";
            ROOT_URL = "https://${cfg.domain}";
            LOCAL_ROOT_URL = "http://unix/";
            UNIX_SOCKET_PERMISSION = "0666";
            SSH_DOMAIN = cfg.domain;
            LANDING_PAGE = "explore";
          };
          federation.ENABLED = true;
        };
      };
    };
  };
}
