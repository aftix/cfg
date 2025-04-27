# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  config,
  lib,
  ...
}: let
  inherit (lib.options) mkEnableOption mkOption;

  atticdCfg = config.services.atticd;

  cfg = config.aftix.attic;
  wwwCfg = config.aftix.www;

  strPort = builtins.toString cfg.port;

  acmeHost =
    if cfg.acmeDomain == null
    then cfg.domain
    else cfg.acmeDomain;
in {
  options.aftix.attic = {
    enable = mkEnableOption "atticd";

    domain = mkOption {
      type = lib.types.str;
    };

    port = mkOption {
      default = 8888;
      type = lib.types.ints.positive;
    };

    acmeDomain = mkOption {
      default = wwwCfg.acmeDomain;
      type = with lib.types; nullOr str;
      description = "null to use \${aftix.attic.domain}";
    };

    region = mkOption {
      default = "us-east-005";
      type = lib.types.str;
    };

    bucket = mkOption {
      default = "aftix-atticd";
      type = lib.types.str;
    };

    endpoint = mkOption {
      default = "https://s3.us-east-005.backblazeb2.com";
      type = lib.types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    aftix.www.nginxBlockerPatches = [./attic_client_user_agent.patch];

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

    sops = {
      secrets = {
        attic_jwt_secret = {};
        attic_s3_key_id = {};
        attic_s3_secret_key = {};
      };

      templates.attic_creds = {
        mode = "0400";
        content = ''
          ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64="${config.sops.placeholder.attic_jwt_secret}"
          AWS_ACCESS_KEY_ID="${config.sops.placeholder.attic_s3_key_id}"
          AWS_SECRET_ACCESS_KEY="${config.sops.placeholder.attic_s3_secret_key}"
        '';
      };
    };

    services = {
      atticd = {
        enable = true;
        environmentFile = config.sops.templates.attic_creds.path;
        settings = {
          allowed-hosts = ["localhost:${strPort}" cfg.domain "www.${cfg.domain}"];
          api-endpoint = "https://${cfg.domain}/";
          listen = "0.0.0.0:${strPort}";

          database.url = "postgresql:///${atticdCfg.user}?host=${config.services.postgresql.settings.unix_socket_directories}";

          chunking = {
            nar-size-threshold = 64 * 1024;
            min-size = 16 * 1024;
            avg-size = 64 * 1024;
            max-size = 256 * 1024;
          };

          storage = {
            inherit (cfg) bucket region endpoint;
            type = "s3";
          };
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
            proxyPass = "http://localhost:${strPort}";
            extraConfig = ''
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;

              client_max_body_size 16G;
            '';
          };
        };
      };

      postgresql = {
        enable = true;
        ensureDatabases = [atticdCfg.user];
        ensureUsers = [
          {
            name = atticdCfg.user;
            ensureDBOwnership = true;
            ensureClauses = {
              login = true;
              replication = true;
            };
          }
        ];
      };
    };
  };
}
