# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
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
    then identityService
    else cfg.acmeDomain;

  inherit (config.aftix.statics) identityService;
in {
  options.my.www.kanidm = {
    enable = mkEnableOption "kanidm";

    port = mkOption {
      default = 8998;
      type = lib.types.ints.positive;
    };

    acmeDomain = mkOption {
      default = wwwCfg.acmeDomain;
      type = with lib.types; nullOr str;
      description = "null to use \${aftix.statics.identityService}";
    };
  };

  config = lib.mkIf cfg.enable {
    security.acme.certs =
      if (acmeHost != identityService)
      then {
        ${acmeHost}.extraDomainNames = [
          "${identityService}"
          "www.${identityService}"
        ];
      }
      else {
        ${acmeHost} = {
          inherit (wwwCfg) group;
          extraDomainNames = ["www.${identityService}"];
        };
      };

    networking.firewall = {
      allowedTCPPorts = [636];
      allowedUDPPorts = [636];
    };

    services = {
      kanidm = {
        clientSettings.uri = "https://${identityService}";
        enableClient = true;
        enableServer = true;
        package = pkgs.kanidm_1_5.override {enableSecretProvisioning = true;};
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

            hydra_users = {
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
                "hydra_users"
              ];
              present = true;
            };

            aftix = {
              displayName = "aftix";
              groups = [
                "forgejo_users"
                "hydra_users"
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
          domain = identityService;
          bindaddress = "[::]:${builtins.toString cfg.port}";
          ldapbindaddress = "0.0.0.0:636";
          online_backup.versions = 7;
          origin = "https://${identityService}";
          tls_key = "/var/lib/acme/${acmeHost}/key.pem";
          tls_chain = "/var/lib/acme/${acmeHost}/fullchain.pem";
          trust_x_forward_for = true;
        };
      };

      nginx = {
        enable = true;
        virtualHosts.${identityService} = {
          serverName = "${identityService} www.${identityService}";
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

    # Can not reverse proxy LDAPS to kanidm - see https://github.com/kanidm/kanidm/issues/3423
    # my.www.streamConfig = [
    #   ''
    #     upstream kanidm_ldaps {
    #       server [::1]:${builtins.toString cfg.ldapPort};
    #     }

    #     server {
    #       listen 636 ssl;
    #       listen [::]:636 ssl;

    #       ssl_protocols TLSv1.2 TLSv1.3;
    #       ssl_ciphers  ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-SHA384:DHE-DSS-AES256-GCM-SHA384:DHE-DSS-AES256-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-SHA256;
    #       ssl_certificate /var/lib/acme/${acmeHost}/fullchain.pem;
    #       ssl_certificate_key /var/lib/acme/${acmeHost}/key.pem;
    #       ssl_trusted_certificate /var/lib/acme/${acmeHost}/chain.pem;
    #       ssl_conf_command Options KTLS;

    #       proxy_pass kanidm_ldaps;
    #     }
    #   ''
    # ];

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
