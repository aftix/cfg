{
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf;
  inherit (lib.options) mkOption mkEnableOption;

  wwwCfg = config.my.www;
  cfg = wwwCfg.metrics;

  acmeHost =
    if cfg.acmeDomain == null
    then cfg.domain
    else cfg.acmeDomain;
in {
  options.my.www.metrics = {
    enable = mkEnableOption "metrics";

    domain = mkOption {
      type = lib.types.str;
    };

    acmeDomain = mkOption {
      default = wwwCfg.acmeDomain;
      type = with lib.types; nullOr str;
      description = "null to use \${my.www.metrics.domain}";
    };

    oidc = {
      enable = mkEnableOption "grafana oidc";

      url = mkOption {
        type = lib.types.nonEmptyStr;
      };

      client-id = mkOption {
        type = lib.types.nonEmptyStr;
      };

      client-secret = mkOption {
        type = lib.types.path;
        description = ''
          sops-nix placeholder for grafana's OIDC client secret
        '';
      };
    };

    otel = {
      http = mkEnableOption "metrics http endpoint";
      grpc = mkEnableOption "metrics grpc endpoint";

      httpPort = mkOption {
        default = 4320;
        type = lib.types.ints.positive;
        description = ''
          Port otel should listen on locally for the HTTP API.
          The public port will always be 4318 in nginx.
        '';
      };

      grpcPort = mkOption {
        default = 4319;
        type = lib.types.ints.positive;
        description = ''
          Port otel should listen on locally for the GRPC API.
          The public port will always be 4317 in nginx.
        '';
      };

      telemetryPort = mkOption {
        default = 4322;
        type = lib.types.ints.positive;
        description = ''
          Port for OTLP-collector to listen to export its own telemetry data.
        '';
      };
    };

    prometheus = {
      port = mkOption {
        default = 4323;
        type = lib.types.ints.positive;
        description = ''
          Port for prometheus to listen on.
        '';
      };

      scrapes = mkOption {
        default = [];
        description = ''
          Configuration for OTLP-collector's prometheus scraper
        '';
        type = with lib.types; listOf (attrsOf unspecified);
      };
    };

    grafana = {
      port = mkOption {
        default = 4323;
        type = lib.types.ints.positive;
      };
    };
  };

  config = mkIf cfg.enable {
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
      postgresql = {
        enable = true;
        ensureDatabases = ["grafana"];
        ensureUsers = [
          {
            name = "grafana";
            ensureDBOwnership = true;
            ensureClauses = {
              login = true;
              replication = true;
            };
          }
        ];
      };

      nginx = {
        enable = true;

        upstreams = {
          grafana = {
            servers."127.0.0.1:${builtins.toString cfg.grafana.port}" = {};
            extraConfig = ''
              keepalive 8;
            '';
          };

          otlp = {
            servers."127.0.0.1:${builtins.toString cfg.otel.httpPort}" = {};
            extraConfig = ''
              keepalive 8;
            '';
          };

          otlp-grpc = {
            servers."127.0.0.1:${builtins.toString cfg.otel.grpcPort}" = {};
            extraConfig = ''
              keepalive 8;
            '';
          };
        };

        virtualHosts = {
          ${cfg.domain} = {
            serverName = "${cfg.domain} www.${cfg.domain}";
            kTLS = true;
            forceSSL = true;
            useACMEHost = acmeHost;

            extraConfig = ''
              include /etc/nginx/bots.d/blockbots.conf;
              include /etc/nginx/bots.d/ddos.conf;
            '';

            locations."/" = {
              proxyPass = "http://grafana";
              extraConfig = ''
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              '';
            };
          };

          "otlp-${cfg.domain}" = {
            serverName = "${cfg.domain} www.${cfg.domain}";
            kTLS = true;
            useACMEHost = acmeHost;
            listen = [
              {
                addr = "0.0.0.0";
                port = 4318;
              }
            ];

            locations."/" = {
              proxyPass = "http://otlp";
              extraConfig = ''
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              '';
            };
          };

          "otlp-grpc-${cfg.domain}" = {
            serverName = "${cfg.domain} www.${cfg.domain}";
            listen = [
              {
                addr = "0.0.0.0";
                port = 4317;
                ssl = true;
              }
              {
                addr = "[::0]";
                port = 4317;
                ssl = true;
              }
            ];

            locations."/" = {
              extraConfig = ''
                grpc_pass grpc://otlp-grpc;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              '';
            };
          };
        };
      };

      # Collect open telemetry traces and scrape prometheus endpoints
      opentelemetry-collector = {
        enable = true;

        settings = {
          extensions = {
            health_check = {};
            resourcedetection = {
              detectors = ["env" "system"];
              override = false;
            };
          };

          receivers = {
            # Listen for incoming OTLP data
            otlp.protocols = {
              grpc.endpoint = mkIf cfg.otel.grpc "127.0.0.1:${builtins.toString cfg.otel.grpcPort}";
              http.endpoint = mkIf cfg.otel.http "127.0.0.1:${builtins.toString cfg.otel.httpPort}";
            };

            # Scrape prometheus endpoints
            prometheus.config = {
              scrape_configs =
                [
                  {
                    job_name = "otel-collector";
                    scrape_interval = "10s";
                    static_configs = [
                      {
                        targets = ["127.0.0.1:${builtins.toString cfg.otel.telemetryPort}"];
                      }
                    ];
                  }
                ]
                ++ cfg.prometheus.scrapes;
            };
          };

          processors = {
            memory_limiter = {
              check_interval = "5s";
              limit_mib = "4000";
              spike_limit_mib = "500";
            };
            batch = {};
          };

          exporters.otlphttp.endpoint = "http://127.0.0.1:${builtins.toString cfg.prometheus.port}/api/v1/otlp";

          service = {
            telemetry = {
              logs.processors = [
                {
                  batch.exporter.otlp = {
                    protocol = "http/protobuf";
                    endpoint = "http://127.0.0.1:${builtins.toString cfg.otel.httpPort}";
                  };
                }
              ];

              metrics = {
                level = "detailed";
                readers = [
                  {
                    pull.exporter.prometheus = {
                      host = "127.0.0.1";
                      port = cfg.otel.telemetryPort;
                    };
                  }
                ];
              };
            };

            pipelines = {
              extensions = ["health_check" "resourcedetection"];
              traces = {
                receivers = ["otlp"];
                processors = ["memory_limiter" "batch"];
                exporters = ["otlphttp"];
              };
              metrics = {
                receivers = ["otlp" "prometheus"];
                processors = ["memory_limiter" "batch"];
                exporters = ["otlphttp"];
              };
            };
          };
        };
      };

      prometheus = {
        enable = true;
        listenAddress = "127.0.0.1";
        port = cfg.prometheus.port;

        configText = ''
          storage:
            tsdb:
              out_of_order_time_window: 30m
          otlp:
            translation_strategy: NoUTF8EscapingWithSuffixes
            promote_resource_attributes:
              - service.instance.id
              - service.name
              - service.namespace
              - cloud.availability_zone
              - cloud.region
              - container.name
              - deployment.environment.name
              - k8s.cluster.name
              - k8s.container.name
              - k8s.cronjob.name
              - k8s.daemonset.name
              - k8s.deployment.name
              - k8s.job.name
              - k8s.namespace.name
              - k8s.pod.name
              - k8s.replicaset.name
              - k8s.statefulset.name
        '';
      };

      grafana = {
        enable = true;

        settings = {
          server = {
            protocol = "socket";
            enforce_domain = true;
            root_url = "https://${cfg.domain}";
            enable_gzip = true;
            socket_mode = "0666";
          };

          database = {
            type = "postgres";
            host = config.services.postgresql.settings.unix_socket_directories;
            user = "grafana";
            url = "postgres:///grafana?host=${config.services.postgresql.settings.unix_socket_directories}";
            ssl_mode = "disable";
            ssl_sni = "0";
          };

          auth = mkIf cfg.oidc.enable {
            disable_login_form = true;
          };

          "auth.generic_oauth" = mkIf cfg.oidc.enable {
            enabled = true;
            client_id = cfg.oidc.client-id;
            client_secret = "\${OIDC_CLIENT_SECRET}";
            auth_url = "${cfg.oidc.url}/oauth2/authorise";
            api_url = "${cfg.oidc.url}/oauth2/openid/${cfg.oidc.client-id}/userinfo";
          };

          log.mode = "syslog file";
        };

        provision = {
          enable = true;
          datasources.settings = {
            apiVersion = 1;
            datasources = [
              {
                name = "opentelemetry-prometheus";
                type = "prometheus";
                access = "proxy";
                url = "http://127.0.0.1:${builtins.toString cfg.prometheus.port}";
                jsonData = {
                  httpMethod = "POST";
                  manageAlerts = true;
                  prometheusType = "Prometheus";
                  prometheusVersion = config.services.prometheus.package.version;
                  cacheLevel = "High";
                  disableRecordingRules = false;
                  incrementalQueryOverlapWindow = "10m";
                };
              }
            ];
          };
        };
      };
    };

    sops.templates.grafana-secrets = {
      mode = "0400";
      owner = "grafana";
      group = "grafana";
      content = let
        oauthSecret = lib.strings.optionalString cfg.oidc.enable cfg.oidc.client-secret;
      in ''
        HOSTNAME=${cfg.domain}
        OIDC_CLIENT_SECRET=${oauthSecret}
      '';
    };

    systemd.services.grafana = {
      serviceConfig.EnvironmentFile =
        config.sops.templates.grafana-secrets.path;
    };
  };
}
