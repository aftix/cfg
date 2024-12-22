{
  lib,
  config,
  ...
}: let
  inherit (lib.options) mkOption mkEnableOption;

  cfg = config.my.www;
  serviceCfg = config.services.forgejo;
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

    security.acme.certs.${cfg.hostname}.extraDomainNames = [
      "${fullHostname}"
      "www.${fullHostname}"
    ];

    services = {
      openssh.settings.AllowUsers =
        lib.lists.optionals
        (!serviceCfg.settings.server.DISABLE_SSH)
        [serviceCfg.user];

      nginx = {
        upstreams.forgejo = {
          servers."unix:${serviceCfg.settings.server.HTTP_ADDR}" = {};
          extraConfig = ''
            keepalive 8;
          '';
        };

        virtualHosts.${fullHostname} = {
          serverName = "${fullHostname} www.${fullHostname}";
          kTLS = true;
          forceSSL = true;
          useACMEHost = cfg.hostname;
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
          database = {
            socket = config.services.postgresql.settings.unix_socket_directories;
            type = "postgresql";
          };
          mailer = {
            ENABLED = true;
            PROTOCOL = "smtps";
          };
          server = {
            DOMAIN = fullHostname;
            PROTOCOL = "http+unix";
            ROOT_URL = "https://${fullHostname}";
            UNIX_SOCKET_PERMISSION = "0666";
          };
        };
      };

      postgresql = {
        enable = true;
        ensureDatabases = ["forgejo"];
        ensureUsers = [
          {
            name = serviceCfg.user;
            ensureDBOwnership = true;
            ensureClauses = {
              login = true;
              replication = true;
            };
          }
        ];
        identMap = lib.mkOverride 60 ''
          superuser_map root postgres
          superuser_map postgres postgres
          superuser_map /^(.*)$ \1
        '';
        authentication = lib.mkOverride 60 ''
          #type database DBuser auth-method
          local sameuser all peer map=superuser_map
        '';
        settings.unix_socket_directories = "/var/run/postgresql";
      };
    };
  };
}
