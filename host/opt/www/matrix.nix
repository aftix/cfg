{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.lists) optional optionals;

  cfg = config.my.matrix;
  wwwCfg = config.my.www;

  inherit (config.my.www) hostname;
  strPort = builtins.toString cfg.port;

  bridgeRegistrationFile = "/var/lib/heisenbridge/registration.yml";
  matrixUser = "matrix-synapse";
  matrixGroup = "matrix-synapse";
  slidingSyncUser = "matrix-sliding-sync";
  slidingSyncGroup = "matrix-sliding-sync";
in {
  options.my.matrix = {
    enable = mkEnableOption "matrix synapse homeserver";
    ircBridge = {
      enable = mkEnableOption "heisenbridge";

      port = mkOption {
        default = 9898;
        type = lib.types.ints.positive;
      };

      namespaces = lib.mkOption {
        description = "Configure the 'namespaces' section of the registration.yml for the bridge and the server";
        type = lib.types.submodule {
          freeformType = (pkgs.formats.json {}).type;
        };

        default = {
          users = [
            {
              regex = "@irc_.*";
              exclusive = true;
            }
          ];
          aliases = [];
          rooms = [];
        };
      };

      identd.enable = lib.mkEnableOption "identd service support";
      identd.port = lib.mkOption {
        type = lib.types.port;
        description = "identd listen port";
        default = 9899;
      };
    };

    port = mkOption {
      default = 9090;
      type = lib.types.ints.positive;
    };
    slidingSyncPort = mkOption {
      default = 8009;
      type = lib.types.ints.positive;
    };

    supportEndpointJSON = mkOption {
      default = {};
      description = "JSON returned by /.well-known/matrix/support";
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      secrets = {
        synapse_registration_token = {
          owner = matrixUser;
          group = matrixGroup;
        };
        synapse_macaroon_key = {
          owner = matrixUser;
          group = matrixGroup;
        };
        matrix_sliding_sync = {
          owner = slidingSyncUser;
          group = slidingSyncGroup;
        };
      };

      templates = {
        "synapse-secrets.yaml" = {
          owner = matrixUser;
          group = matrixGroup;
          content =
            /*
            yaml
            */
            ''
              registration_shared_secret: "${config.sops.placeholder.synapse_registration_token}"
              macaroon_secret_key: "${config.sops.placeholder.synapse_macaroon_key}"
            '';
        };

        "sliding-sync-secret.env" = {
          owner = slidingSyncUser;
          group = slidingSyncGroup;
          content =
            /*
            env
            */
            ''
              SYNCV3_SECRET="${config.sops.placeholder.matrix_sliding_sync}"
            '';
        };
      };
    };

    my.www.streamConfig = let
      sPort = builtins.toString cfg.ircBridge.identd.port;
    in
      optional cfg.ircBridge.identd.enable ''
        upstream identd {
          server 127.0.0.1:${sPort};
        }

        server {
          listen 113;
          listen [::]:113;

          proxy_pass identd;
        }
      '';

    # These locale settings are expected to be set on the psql db by matrix-synapse
    i18n = {
      extraLocaleSettings = {
        LC_CTYPE = "C.UTF-8";
        LC_COLLATE = "C.UTF-8";
      };
    };

    # Overwrite module service configurations to allow for sops secrets
    systemd.services = {
      heisenbridge = let
        pkg = pkgs.heisenbridge;
        bin = "${pkg}/bin/heisenbridge";

        # JSON is a proper subset of YAML
        bridgeConfig = builtins.toFile "heisenbridge-registration.yml" (builtins.toJSON {
          id = "heisenbridge";
          url = "http://localhost:${builtins.toString config.services.heisenbridge.port}";
          # Don't specify as_token and hs_token
          rate_limited = false;
          sender_localpart = "heisenbridge";
          inherit (cfg.ircBridge) namespaces;
          heisenbridge.media_url = "https://${wwwCfg.hostname}";
        });
      in
        lib.mkIf cfg.ircBridge.enable {
          description = "Matrix<->IRC bridge";
          before = ["matrix-synapse.service"]; # So the registration file can be used by Synapse
          wantedBy = ["multi-user.target"];

          preStart = ''
            umask 077
            set -e -u -o pipefail

            if ! [ -f "${bridgeRegistrationFile}" ]; then
              # Generate registration file if not present (actually, we only care about the tokens in it)
              ${bin} --generate --config ${bridgeRegistrationFile}
            fi

            # Overwrite the registration file with our generated one (the config may have changed since then),
            # but keep the tokens. Two step procedure to be failure safe
            ${pkgs.yq}/bin/yq --slurp \
              '.[0] + (.[1] | {as_token, hs_token})' \
              ${bridgeConfig} \
              ${bridgeRegistrationFile} \
              > ${bridgeRegistrationFile}.new
            mv -f ${bridgeRegistrationFile}.new ${bridgeRegistrationFile}
          '';

          serviceConfig = rec {
            Type = "simple";
            ExecStart = lib.concatStringsSep " " ([
                bin
                "-v"
                "--config"
                bridgeRegistrationFile
                "--listen-address"
                "0.0.0.0"
                "--listen-port"
                (builtins.toString cfg.ircBridge.port)
                "--owner"
                "@aftix:matrix.org"
              ]
              ++ (optionals cfg.ircBridge.identd.enable [
                "--identd-port"
                (builtins.toString cfg.ircBridge.identd.port)
              ])
              ++ [
                "http://localhost:${strPort}"
              ]);

            # Hardening options

            User = matrixUser;
            Group = matrixGroup;
            RuntimeDirectory = "heisenbridge";
            RuntimeDirectoryMode = "0700";
            StateDirectory = "heisenbridge";
            StateDirectoryMode = "0755";

            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            PrivateDevices = true;
            ProtectKernelTunables = true;
            ProtectControlGroups = true;
            RestrictSUIDSGID = true;
            PrivateMounts = true;
            ProtectKernelModules = true;
            ProtectKernelLogs = true;
            ProtectHostname = true;
            ProtectClock = true;
            ProtectProc = "invisible";
            ProcSubset = "pid";
            RestrictNamespaces = true;
            RemoveIPC = true;
            UMask = "0077";

            CapabilityBoundingSet = ["CAP_CHOWN"] ++ optional (cfg.port < 1024) "CAP_NET_BIND_SERVICE";
            AmbientCapabilities = CapabilityBoundingSet;
            NoNewPrivileges = true;
            LockPersonality = true;
            RestrictRealtime = true;
            SystemCallFilter = ["@system-service" "~@privileged" "@chown"];
            SystemCallArchitectures = "native";
            RestrictAddressFamilies = "AF_INET AF_INET6";
          };
        };

      matrix-sliding-sync = {
        after = lib.mkForce ["postgresql.service" "matrix-synapse.service"];
        serviceConfig = {
          DynamicUser = lib.mkForce false;
          User = lib.mkForce slidingSyncUser;
          Group = lib.mkForce slidingSyncGroup;
          WorkingDirectory = lib.mkForce config.services.matrix-sliding-sync.package;
        };
      };
    };

    services = {
      postgresql = {
        enable = true;
        ensureDatabases = [matrixUser slidingSyncUser];
        ensureUsers = [
          {
            name = matrixUser;
            ensureDBOwnership = true;
            ensureClauses = {
              login = true;
              replication = true;
            };
          }
          {
            name = slidingSyncUser;
            ensureDBOwnership = true;
            ensureClauses = {
              login = true;
              replication = true;
            };
          }
        ];
        identMap = lib.mkForce ''
          superuser_map root postgres
          superuser_map postgres postgres
          superuser_map /^(.*)$ \1
        '';
        authentication = lib.mkForce ''
          #type database DBuser auth-method
          local sameuser all peer map=superuser_map
        '';
        settings.unix_socket_directories = "/var/run/postgresql";
      };

      matrix-synapse = {
        enable = assert wwwCfg.blog; assert cfg.ircBridge.enable -> cfg.enable; true;
        settings = {
          server_name = hostname;
          public_baseurl = "https://${hostname}/";
          suppress_key_server_warning = true;

          database = {
            name = "psycopg2";
            allow_unsafe_locale = true; # matrix-synapse only accepts "C", not "C.UTF-8", but nixos only has "C.UTF-8"
            args = {
              user = matrixUser;
              host = config.services.postgresql.settings.unix_socket_directories;
              cp_min = 5;
              cp_max = 10;
            };
          };
          # database.name = "sqlite3";

          trusted_key_servers = [
            {
              server_name = "matrix.org";
            }
          ];

          app_service_config_files = optional cfg.ircBridge.enable bridgeRegistrationFile;

          listeners = [
            {
              bind_addresses = ["127.0.0.1"];
              port = cfg.port;
              tls = false;
              type = "http";
              x_forwarded = true;
              resources = [
                {
                  compress = false;
                  names = ["federation" "client" "keys" "media" "static"];
                }
              ];
            }
          ];
        };

        extraConfigFiles = [config.sops.templates."synapse-secrets.yaml".path];
      };

      matrix-sliding-sync = {
        enable = true;
        environmentFile = config.sops.templates."sliding-sync-secret.env".path;
        createDatabase = false;
        settings = {
          SYNCV3_SERVER = pkgs.lib.strings.removeSuffix "/" config.services.matrix-synapse.settings.public_baseurl;
          SYNCV3_BINDADDR = "127.0.0.1:${builtins.toString cfg.slidingSyncPort}";
          SYNCV3_DB = "postgresql:///${slidingSyncUser}?host=${config.services.postgresql.settings.unix_socket_directories}";
        };
      };

      nginx = {
        upstreams =
          {
            matrix-synapse = {
              servers."localhost:${strPort}" = {};
              extraConfig = ''
                zone synapse 64k;
                keepalive 8;
              '';
            };
            matrix-sliding-sync = {
              servers."localhost:${builtins.toString cfg.slidingSyncPort}" = {};
              extraConfig = ''
                zone sliding_sync 64k;
                keepalive 8;
              '';
            };
          }
          // optionalAttrs cfg.ircBridge.enable {
            heisenbridge = {
              servers."localhost:${builtins.toString cfg.ircBridge.port}" = {};
              extraConfig = ''
                keepalive 8;
              '';
            };
          };

        virtualHosts.${hostname}.locations = let
          mkEndpoint = data: {
            extraConfig = ''
              default_type application/json;
              add_header Access-Control-Allow-Origin *;
              add_header Access-Control-Allow-Methods "GET, POST, DELETE, OPTIONS";
              add_header Access-Control-Allow-Headers "X-Requested-With, Content-Type, Authorization";
              return 200 '${builtins.toJSON data}';
            '';
          };
        in
          {
            "~* ^(\\/_matrix\\/push)" = {
              proxyPass = "http://matrix-sliding-sync";
              extraConfig = ''
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
              '';
            };

            "~ ^/(client/|_matrix/client/unstable/org.matrix.msc3575/sync)" = {
              proxyPass = "http://matrix-sliding-sync";
              extraConfig = ''
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
              '';
            };

            "~* ^(\\/_matrix|\\/_synapse\\/client)" = {
              proxyPass = "http://matrix-synapse";
              extraConfig = ''
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;

                client_max_body_size 100M;
              '';
            };

            "/.well-known/matrix/server" = mkEndpoint {"m.server" = "${hostname}:443";};
            "/.well-known/matrix/client" = mkEndpoint {
              "m.homeserver".base_url = "https://${hostname}";
              "org.matrix.msc3575.proxy".url = "https://${hostname}";
            };
            "/.well-known/matrix/support" = mkEndpoint cfg.supportEndpointJSON;
          }
          // optionalAttrs cfg.ircBridge.enable {
            "/_heisenbridge/media/" = {
              proxyPass = "http://heisenbridge";
              extraConfig = ''
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
              '';
            };
          };
      };
    };

    networking.firewall = {
      allowedTCPPorts = optional cfg.ircBridge.identd.enable 113;
      allowedUDPPorts = optional cfg.ircBridge.identd.enable 113;
    };

    users = rec {
      users.${slidingSyncUser} = {
        group = slidingSyncGroup;
        isSystemUser = true;
        createHome = false;
        uid = 10555;
      };

      groups.${slidingSyncGroup}.gid = users.${slidingSyncUser}.uid;
    };
  };
}
