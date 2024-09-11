{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.strings) escapeShellArg;

  cfg = config.services.znc;
  inherit (config.my.www) hostname;
  inherit (config.my.znc) subdomain;
in {
  options.my.znc = {
    enable = mkEnableOption "znc";
    subdomain = mkOption {
      default = "irc";
      type = lib.types.str;
    };
  };

  config = lib.mkIf config.my.znc.enable {
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

    my.www.streamConfig = [
      ''
        upstream znc {
          server [::1]:7001;
        }

        server {
          listen 6697 ssl;
          listen [::]:6697 ssl;

          ssl_protocols TLSv1.2 TLSv1.3;
          ssl_ciphers  ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-SHA384:DHE-DSS-AES256-GCM-SHA384:DHE-DSS-AES256-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-SHA256;
          ssl_certificate /var/lib/acme/${hostname}/fullchain.pem;
          ssl_certificate_key /var/lib/acme/${hostname}/key.pem;
          ssl_trusted_certificate /var/lib/acme/${hostname}/chain.pem;
          ssl_conf_command Options KTLS;

          proxy_pass znc;
        }
      ''
    ];

    networking.firewall = {
      allowedTCPPorts = [6697];
      allowedUDPPorts = [6697];
    };

    security.acme.certs.${hostname}.extraDomainNames = [
      "${subdomain}.${hostname}"
      "www.${subdomain}.${hostname}"
    ];

    systemd = {
      tmpfiles.rules = [
        "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group} -"
        "d ${cfg.dataDir}/configs 0750 ${cfg.user} ${cfg.group} -"
      ];

      services.znc = {
        after = ["acme-${hostname}.service"];
        preStart = let
          inherit (lib.strings) optionalString;
          modules = pkgs.buildEnv {
            name = "znc-modules";
            paths = config.services.znc.modulePackages;
          };
          passwordSecretPath = escapeShellArg config.sops.secrets.znc_password.path;
          passwordSaltSecretPath = escapeShellArg config.sops.secrets.znc_passwordsalt.path;
          twitchOauthSecretPath = escapeShellArg config.sops.secrets.znc_twitchoauth.path;
        in
          lib.mkForce
          /*
          bash
          */
          ''
            mkdir -p ${cfg.dataDir}/configs

            # If mutable, regenerate conf file every time.
            ${optionalString (!cfg.mutable) ''
              echo "znc is set to be system-managed. Now deleting old znc.conf file to be regenerated."
              rm -f ${cfg.dataDir}/configs/znc.conf
            ''}

            # Ensure essential files exist.
            if [[ ! -f ${cfg.dataDir}/configs/znc.conf ]]; then
                echo "No znc.conf file found in ${cfg.dataDir}. Creating one now."
                cp --no-preserve=ownership --no-clobber ${cfg.configFile} ${cfg.dataDir}/configs/znc.conf
                chmod u+rw ${cfg.dataDir}/configs/znc.conf
            fi

            if [[ ! -f ${cfg.dataDir}/znc.pem ]]; then
              echo "No znc.pem file found in ${cfg.dataDir}. Creating one now."
              ${pkgs.znc}/bin/znc --makepem --datadir ${cfg.dataDir}
            fi

            # Symlink modules
            rm ${cfg.dataDir}/modules || true
            ln -fs ${modules}/lib/znc ${cfg.dataDir}/modules

            # Insert secrets
            [[ -f ${passwordSecretPath} ]] || exit 1
            [[ -f ${passwordSaltSecretPath} ]] || exit 1
            [[ -f ${twitchOauthSecretPath} ]] || exit 1
            mv ${cfg.dataDir}/configs/znc.conf ${cfg.dataDir}/configs/znc.conf.old
            ${pkgs.gnused}/bin/sed -e "s/__PASSWORD__/$(cat ${passwordSecretPath})/g" -e "s/__SALT__/$(cat ${passwordSaltSecretPath})/g" -e "s/__TWITCHOAUTH__/$(cat ${twitchOauthSecretPath})/g" ${cfg.dataDir}/configs/znc.conf.old > ${cfg.dataDir}/configs/znc.conf
            rm ${cfg.dataDir}/configs/znc.conf.old
          '';
      };
    };

    services = {
      nginx.virtualHosts."${subdomain}.${hostname}" = {
        serverName = "${subdomain}.${hostname} www.${subdomain}.${hostname}";
        kTLS = true;
        forceSSL = true;
        useACMEHost = hostname;

        locations."/" = {
          proxyPass = "http://[::1]:7000/";
          extraConfig = ''
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          '';
        };

        extraConfig = ''
          include /etc/nginx/bots.d/blockbots.conf;
          include /etc/nginx/bots.d/ddos.conf;
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
              Port = 7001;
              Host = "::1";
              URIPrefix = "/";
            };

            listener1 = {
              AllowIRC = false;
              AllowWeb = true;
              IPv4 = false;
              IPv6 = true;
              Host = "::1";
              Port = 7000;
              URIPrefix = "/";
            };

            l = lib.mkForce null;
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
            LoadModule = [
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
                  Server = "irc.snoonet.org +6697";
                }
                // network;

              twitch =
                {
                  Server = "irc.chat.twitch.tv +6697 __TWITCHOAUTH__";
                }
                // network;
            };

            Pass.password = {
              Hash = "__PASSWORD__";
              Method = "SHA256";
              Salt = "__SALT__";
            };
          };
        };
      };
    };
  };
}
