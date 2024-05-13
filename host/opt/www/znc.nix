{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.strings) escapeShellArg;
  cfg = config.services.znc;
  hostname = config.my.www.hostname;
  subdomain = config.my.znc.subdomain;
in {
  options.my.znc = {
    enable = mkEnableOption "znc";
    subdomain = mkOption {
      default = "irc";
      type = lib.types.str;
    };
  };

  config = {
    sops.secrets = {
      znc_password = {
        inherit (cfg) group;
        owner = cfg.user;
      };
      znc_passwordsalt = {
        inherit (cfg) group;
        owner = cfg.user;
      };
      znc_twitchoauth = {
        inherit (cfg) group;
        owner = cfg.user;
      };
    };

    systemd = {
      services = {
        znc-init = {
          description = "Initialize znc settings";
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            User = cfg.user;
            Group = cfg.group;
            RuntimeDirectory = cfg.dataDir;
            RuntimeDirectoryMode = "750";
            NoNewPrivileges = true;
            ProtectSystem = "strict";
            ReadWritePaths = cfg.dataDir;
            ProtectHome = true;
            StateDirectory = cfg.dataDir;
            StateDirectoryMode = "755";
            PrivateTmp = true;
            ProtectHostname = true;
            ProtectClock = true;
            ProtectKernelTunables = true;
            ProtectKernelModules = true;
            ProtectKernelLogs = true;
            ProtectControlGroups = true;
            RestrictNamespaces = true;
            RestrictRealtime = true;
            RestrictSUIDSGID = true;
            RemoveIPC = true;
            PrivateNetwork = true;
          };
          script = let
            passwordSecretPath = escapeShellArg config.sops.secrets.znc_password.path;
            passwordSaltSecretPath = escapeShellArg config.sops.secrets.znc_passwordsalt.path;
            twitchOauthSecretPath = escapeShellArg config.sops.secrets.znc_twitchoauth.path;
          in ''
            cd ${cfg.dataDir}/configs || exit 1
            [[ -f ${passwordSecretPath} ]] || exit 1
            [[ -f ${passwordSaltSecretPath} ]] || exit 1
            [[ -f ${twitchOauthSecretPath} ]] || exit 1
            ${pkgs.gnused}/bin/sed -i"" -e "s/PASSWORD/$(cat ${passwordSecretPath})/g" znc.conf
            ${pkgs.gnused}/bin/sed -i"" -e "s/PASSWORD/$(cat ${passwordSaltSecretPath})/g" znc.conf
            ${pkgs.gnused}/bin/sed -i"" -e "s/PASSWORD/$(cat ${twitchOauthSecretPath})/g" znc.conf
          '';
        };

        znc = {
          requires = ["znc-init.service"];
          after = ["znc-init.service"];
        };
      };
    };

    services = {
      nginx = {
        virtualHosts."${subdomain}.${hostname}" = {
          serverName = "${subdomain}.${hostname} www.${subdomain}.${hostname}";
          kTLS = true;
          forceSSL = true;
          useACMEHost = hostname;

          locations =
            {
              "/" = {
                proxyPass = "http://[[::1]]:7001/";
                extraConfig = ''
                  proxy_set_header X-Real-IP $remote_addr;
                  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                '';
              };
            }
            // config.my.www.acme-location-block;
        };

        streamConfig = ''
          upstream znc {
            server [::1]::7000;
          }

          server {
            listen 0.0.0.0:6697 http2 ssl;
            listen [::0]:6697 http2 ssl;

            ssl_certificate ${config.security.acme.certs.${hostname}.directory}/fullchain.pem;
            ssl_certificate_key ${config.security.acme.certs.${hostname}.directory}/key.pem;
            ssl_trusted_certificate ${config.security.acme.certs.${hostname}.directory}/chain.pem;
            ssl_conf_command Options KTLS;

            proxy_pass znc;
          }
        '';
      };

      znc = {
        inherit (config.my.www) user group;
        enable = true;
        mutable = false;
        modulePackages = with pkgs.zncModules; [
          clientbuffer
        ];

        useLegacyConfig = false;
        config = {
          AnonIPLimit = 10;
          AuthOnlyViaModule = false;
          ConfigWriteDelay = 0;
          ConnectDelay = 5;
          HideVersion = false;
          MaxBufferSize = 500;
          ProtectWebSessions = true;
          ServerThrottle = 30;
          LoadModule = [
            "webadmin"
            "certauth"
          ];

          TrustedProxy = [
            "127.0.0.1"
            "::1"
          ];

          Listener = {
            listener0 = {
              AllowIRC = true;
              AllowWeb = false;
              IPv4 = false;
              IPv6 = true;
              Port = 7000;
              URIPrefix = "/";
            };

            listener1 = {
              AllowIRC = false;
              AllowWeb = true;
              IPv4 = false;
              IPv6 = true;
              Port = 7001;
              URIPrefix = "/";
            };
          };

          User.aftix = {
            AltNick = "aftix_";
            Ident = "aftix";
            Nick = "aftix";
            RealName = "aftix";

            Admin = true;
            AppendTimestamp = false;
            AuthOnlyViaModule = false;
            AutoClearChanBuffer = false;
            AutoClearQueryBuffer = false;
            ChanBufferSize = 50;
            DenyLoadMod = false;
            DenySetBindHost = false;
            JoinTries = 10;
            MaxJoins = 0;
            MaxNetworks = 1;
            LoadModul = [
              "chansaver"
              "controlpanel"
              "dcc"
              "webadmin"
            ];

            MaxQueryBuffers = 50;
            MultiClients = true;
            NoTrafficTimeout = 180;
            PrependTimestamp = true;
            QueryBufferSize = 50;
            QuitMsg = "%znc%";
            StatusPrefix = "*";
            TimestampFormat = "[%H:%M:%S]";

            Network = let
              network = {
                LoadModule = [
                  "cert"
                  "sasl"
                  "simple_away"
                  "keepnick"
                  "savebuff"
                  "clientbuffer"
                  "autoadd"
                  "route_replies"
                ];
                FloodBurst = 9;
                FloodRate = "2.00";
                IRCConnectEnabled = true;
                JoinDelay = 0;
                TrustAllCerts = false;
                TrustPKI = true;
              };
            in {
              oftc =
                {
                  Server = "irc.oftc.net + 6697";
                }
                // network;

              esper =
                {
                  Server = "irc.esper.net +6697";
                  Chan."#squirrels" = {};
                }
                // network;

              libera =
                {
                  Server = "irc.libera.chat +6697";
                }
                // network;

              snoonet =
                {
                  Server = "irc.snoonet.org 6667";
                }
                // network;

              twitch =
                {
                  Server = "irc.chat.twitch.tv 6667 TWITCHOAUTH";
                }
                // network;
            };

            Pass.password = {
              Hash = "PASSWORD";
              Method = "SHA256";
              Salt = "PASSWORDSALT";
            };
          };
        };
      };
    };
  };
}
