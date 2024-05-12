{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib.strings) escapeShellArg;
  cfg = config.services.znc;
in {
  options.my.znc.hostname = mkOption {
    default = "aftix.xyz";
    type = lib.types.str;
  };

  config = {
    networking.firewall = {
      allowedTCPPorts = [6697];
      allowedUDPPorts = [6697];
    };

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
        znc-init-keys = {
          description = "Initialize znc certificates";
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            WorkingDirectory = cfg.dataDir;
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
            keysDir = escapeShellArg config.security.acme.certs.${config.my.znc.hostname}.directory;
          in ''
            cat ${keysDir}/privkey.pem ${keysDir}/fullchain.pem > ${escapeShellArg cfg.dataDir}/znc.pem
            chown -R ${cfg.user}:${cfg.group} ${escapeShellArg cfg.dataDir}
            chmod 0600 ${escapeShellArg cfg.dataDir}/znc.pem
          '';
        };
        znc-init = {
          description = "Initialize znc settings";
          requires = ["znc-init-keys.service"];
          after = ["znc-init-keys.service"];
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

    services.znc = {
      enable = true;
      modulePackages = with pkgs.zncModules; [
        clientbuffer
      ];

      useLegacyConfig = false;
      config = rec {
        AnonIPLimit = 10;
        AuthOnlyViaModule = false;
        ConfigWriteDelay = 0;
        ConnectDelay = 5;
        HideVersion = false;
        MaxBufferSize = 500;
        ProtectWebSessions = true;
        SSLCertFile = "${cfg.dataDir}/znc.pem";
        SSLDHParamFile = SSLCertFile;
        SSLKeyFile = SSLCertFile;
        ServerThrottle = 30;
        LoadModule = [
          "webadmin"
          "certauth"
        ];

        Listener.listener0 = {
          AllowIRC = true;
          AllowWeb = true;
          IPv4 = true;
          IPv6 = true;
          Port = 6697;
          SSL = true;
          URIPrefix = "/";
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
}
