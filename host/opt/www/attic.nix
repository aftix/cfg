{
  config,
  lib,
  ...
}: let
  inherit (lib.options) mkOption;

  atticdCfg = config.services.atticd;
  cfg = config.my.attic;
  wwwCfg = config.my.www;
  strPort = builtins.toString cfg.port;
  fullHostname = "${cfg.subdomain}.${wwwCfg.hostname}";
in {
  options.my.attic = {
    port = mkOption {
      default = 8888;
      type = lib.types.ints.positive;
    };

    subdomain = mkOption {
      default = "attic";
      type = lib.types.str;
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

  config = lib.mkIf atticdCfg.enable {
    my.www.nginxBlockerPatches = [./attic_client_user_agent.patch];
    security.acme.certs.${wwwCfg.hostname}.extraDomainNames = [
      fullHostname
      "www.${fullHostname}"
    ];

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
        credentialsFile = config.sops.templates.attic_creds.path;
        settings = {
          allowed-hosts = ["localhost:${strPort}" fullHostname "www.${fullHostname}"];
          api-endpoint = "https://${fullHostname}/";
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

      nginx.virtualHosts.${fullHostname} = {
        serverName = "${fullHostname} www.${fullHostname}";
        kTLS = true;
        forceSSL = true;
        useACMEHost = wwwCfg.hostname;
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
