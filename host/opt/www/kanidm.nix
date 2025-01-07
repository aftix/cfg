{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.options) mkOption mkEnableOption;

  wwwCfg = config.my.www;
  cfg = config.my.www.kanidm;

  acmeHost =
    if cfg.acmeDomain == null
    then cfg.domain
    else cfg.acmeDomain;
in {
  options.my.www.kanidm = {
    enable = mkEnableOption "kanidm";

    domain = mkOption {
      type = lib.types.str;
    };

    port = mkOption {
      default = 8998;
      type = lib.types.ints.positive;
    };

    acmeDomain = mkOption {
      default = wwwCfg.acmeDomain;
      type = with lib.types; nullOr str;
      description = "null to use \${my.www.kanidm.domain}";
    };
  };

  config = lib.mkIf cfg.enable {
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
      kanidm = {
        clientSettings.uri = "https://${cfg.domain}";
        enableClient = true;
        enableServer = true;
        package = pkgs.kanidm_1_4.override {enableSecretProvisioning = true;};
        provision = {
          enable = true;
          adminPasswordFile = config.sops.secrets.kanidm_admin_password.path;
          idmAdminPasswordFile = config.sops.secrets.kanidm_idmadmin_password.path;
          instanceUrl = "https://localhost:${builtins.toString cfg.port}";

          groups = {
            administrators = {
              present = true;
              members = ["administrator"];
            };

            forgejo_users = {
              present = true;
              members = [
                "administrator"
                "aftix"
              ];
            };
          };

          persons = {
            administrator = {
              displayName = "Administrator";
              groups = [
                "administrators"
                "forgejo_users"
              ];
              present = true;
            };

            aftix = {
              displayName = "aftix";
              groups = [
                "forgejo_users"
              ];
              mailAddresses = ["aftix@aftix.xyz"];
              present = true;
            };
          };

          systems.oauth2.forgejo = {
            allowInsecureClientDisablePkce = true;
            displayName = "Forgejo";
            present = true;
            originLanding = "https://forge.aftix.xyz/";
            originUrl = "https://forge.aftix.xyz/user/oauth2/kanidm/callback";
            scopeMaps.forgejo_users = ["email" "groups" "openid" "profile"];
          };
        };
        serverSettings = {
          inherit (cfg) domain;
          bindaddress = "127.0.0.1:${builtins.toString cfg.port}";
          online_backup.versions = 7;
          origin = "https://${cfg.domain}";
          tls_key = "/var/lib/acme/${acmeHost}/key.pem";
          tls_chain = "/var/lib/acme/${acmeHost}/fullchain.pem";
          trust_x_forward_for = true;
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

          locations."/" = {
            proxyPass = "https://localhost:${builtins.toString cfg.port}";
            extraConfig = ''
              proxy_http_version 1.1;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
            '';
          };
        };
      };
    };

    sops.secrets = {
      kanidm_admin_password = {
        owner = "kanidm";
        group = "kanidm";
      };
      kanidm_idmadmin_password = {
        owner = "kanidm";
        group = "kanidm";
      };
    };

    users.users.kanidm = {
      extraGroups = [wwwCfg.group];
      shell = lib.getExe' pkgs.util-linux "nologin";
    };
  };
}
