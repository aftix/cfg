# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  wwwCfg = config.aftix.www;
  cfg = config.aftix.www.hydra;

  acmeHost =
    if cfg.acmeDomain == null
    then cfg.domain
    else cfg.acmeDomain;

  psqlDir = "/var/run/postgresql";
in {
  imports = [../hydra-substituter.nix];

  options.aftix.www.hydra = {
    enable = mkEnableOption "hydra";

    domain = mkOption {
      type = lib.types.str;
    };

    acmeDomain = mkOption {
      default = wwwCfg.acmeDomain;
      type = with lib.types; nullOr str;
      description = "null to use \${config.aftix.www.blog.domain}";
    };

    port = mkOption {
      default = 9998;
      type = lib.types.ints.positive;
    };

    store_uri = mkOption {
      default = null;
      type = lib.types.nullOr (lib.types.uniq lib.types.str);
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

    aftix.www = {
      extraPsqlIdentMap = [
        "hydra_map root postgres"
        "hydra_map hydra-queue-runner hydra"
        "hydra_map hydra-www hydra"
        "hydra_map /^(.*)$ \\1"
      ];

      extraPsqlAuthentication = [
        {
          type = "local";
          database = "hydra";
          user = "all";
          auth-method = "peer";
          auth-options.map = "hydra_map";
        }
      ];
    };

    nix.settings.allowed-uris = [
      "github:"
      "gitlab:"
      "git+https:"
    ];

    services = {
      hydra = {
        inherit (cfg) port;

        enable = true;

        notificationSender = "hydra@aftix.xyz";
        hydraURL = cfg.domain;
        smtpHost = "smtp.mailbox.org";
        useSubstitutes = true;
        dbi = "dbi:Pg:dbname=hydra;host=${psqlDir};user=hydra;";

        extraConfig =
          (
            lib.optionalString (cfg.store_uri != null) "store_uri = ${cfg.store_uri}\n"
          )
          +
          /*
          apache
          */
          ''
            compress_build_logs = 1
            compress_build_logs_compression = zstd
            <dynamicruncommand>
              enable = 1
            </dynamicruncommand>
            Include ${config.sops.templates.hydraConfig.path}
            email_notification = 1
            <ldap>
              <config>
                <credential>
                  class = Password
                  password_field = password
                  password_type = self_check
                </credential>
                <store>
                  class = LDAP
                  ldap_server = identity.aftix.xyz
                  <ldap_server_options>
                    scheme = ldaps
                    timeout = 30
                  </ldap_server_options>
                  binddn = "dn=token"
                  include ${config.sops.templates.hydraLdap.path}
                  start_tls = 0
                  user_basedn = "dc=identity,dc=aftix,dc=xyz"
                  user_filter = "(&(class=posixaccount)(spn=%s@identity.aftix.xyz))"
                  user_scope = subtree
                  user_field = name
                  use_roles = 1
                  <user_search_options>
                    attrs = name
                    attrs = spn
                    attrs = sn
                    attrs = cn
                    attrs = mail
                  </user_search_options>
                  role_basedn = "dc=identity,dc=aftix,dc=xyz"
                  role_filter = "(&(class=group)(member=%s))"
                  role_scope = subtree
                  role_field = name
                  role_value = spn
                  <role_search_options>
                    attrs = name
                    attrs = spn
                    attrs = cn
                    attrs = member
                  </role_search_options>
                  persist_in_session = all
                </store>
              </config>
              <role_mapping>
                administrators = admin
                hydra_users = bump-to-front
                hydra_users = restart-jobs
                hydra_users = cancel-build
                hydra_users = create-projects
              </role_mapping>
            </ldap>
          '';
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

          locations."/".proxyPass = "http://localhost:${builtins.toString cfg.port}";
        };
      };

      postgresql = {
        enable = true;
        ensureDatabases = ["hydra"];
        ensureUsers = [
          {
            name = "hydra";
            ensureDBOwnership = true;
            ensureClauses = {
              login = true;
              replication = true;
            };
          }
        ];
        settings.unix_socket_directories = psqlDir;
      };
    };

    sops = {
      secrets = {
        hydra_gha_token = {
          mode = "0440";
          owner = "hydra";
          group = "hydra";
        };

        hydra_forgejo_user = {
          mode = "0440";
          owner = "hydra";
          group = "hydra";
        };
        hydra_forgejo_token = {
          mode = "0440";
          owner = "hydra";
          group = "hydra";
        };

        hydra_smtp_user = {
          mode = "0440";
          owner = "hydra";
          group = "hydra";
        };
        hydra_smtp_password = {
          mode = "0440";
          owner = "hydra";
          group = "hydra";
        };
        hydra_smtp_port = {
          mode = "0440";
          owner = "hydra";
          group = "hydra";
        };

        hydra_ldap_bindpw = {
          mode = "0440";
          owner = "hydra";
          group = "hydra";
        };

        hydra_store_bucket = {
          mode = "0440";
          owner = "hydra";
          group = "hydra";
        };
        hydra_store_url = {
          mode = "0440";
          owner = "hydra";
          group = "hydra";
        };
        hydra_store_key_id = {
          mode = "0440";
          owner = "hydra";
          group = "hydra";
        };
        hydra_store_token = {
          mode = "0440";
          owner = "hydra";
          group = "hydra";
        };
        hydra_store_secret_key = {
          mode = "0440";
          owner = "hydra";
          group = "hydra";
        };
        hydra_store_public_key = {
          mode = "0444";
          owner = "hydra";
          group = "hydra";
        };
      };

      templates = {
        hydraConfig = {
          mode = "0440";
          owner = "hydra";
          group = "hydra";
          content = ''
            <github_authorization>
              NixOS = Bearer ${config.sops.placeholder.hydra_gha_token}
            </github_authorization>
            <gitea_authorization>
              ${config.sops.placeholder.hydra_forgejo_user}=${config.sops.placeholder.hydra_forgejo_token}
            </gitea_authorization>
          '';
        };

        hydraLdap = {
          mode = "0440";
          owner = "hydra";
          group = "hydra";
          content = ''
            bindpw = ${config.sops.placeholder.hydra_ldap_bindpw}
          '';
        };

        hydraStore = {
          mode = "0444";
          owner = "hydra";
          group = "hydra";
          content = ''
            AWS_ACCESS_KEY_ID=${config.sops.placeholder.hydra_store_key_id}
            AWS_SECRET_ACCESS_KEY=${config.sops.placeholder.hydra_store_token}
          '';
        };

        hydraEnv = {
          mode = "0440";
          owner = "hydra";
          group = "hydra";
          content = ''
            EMAIL_SENDER_TRANSPORT_sasl_username=${config.sops.placeholder.hydra_smtp_user}
            EMAIL_SENDER_TRANSPORT_sasl_password=${config.sops.placeholder.hydra_smtp_password}
            EMAIL_SENDER_TRANSPORT_port=${config.sops.placeholder.hydra_smtp_port}
            EMAIL_SENDER_TRANSPORT_ssl=1
          '';
        };
      };
    };

    systemd.services = let
      credsFile = config.aftix.hydra-substituter.credentials-file-path;
    in
      lib.recursiveUpdate
      {
        hydra-notify = {
          serviceConfig.EnvironmentFile = [config.sops.templates.hydraEnv.path] ++ lib.optionals (credsFile != null) [credsFile];
          path = [pkgs.msmtp];
        };

        hydra-queue-runner.path = [pkgs.msmtp];
        hydra-server.path = [pkgs.msmtp];

        # Since DBI string isn't exactly what the module expects, this isn't added by it
        hydra-init.after = ["postgresql.service"];
      }
      (lib.optionalAttrs (credsFile != null) {
        hydra-evaluator.serviceConfig.EnvironmentFile = credsFile;
        hydra-queue-runner.serviceConfig.EnvironmentFile = credsFile;
      });
  };
}
