{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.strings) escapeShellArg;
  inherit (lib.lists) optional optionals;

  cfg = config.my.matrix;
  wwwCfg = config.my.www;

  inherit (config.my.www) hostname;
  strPort = builtins.toString cfg.port;

  launchWithSecrets = pkgs.writeShellApplication {
    name = "launch-with-secrets";
    runtimeInputs = with pkgs; [gnused coreutils-full config.services.matrix-conduit.package];
    text = let
      registrationSecretPath = escapeShellArg config.sops.secrets.conduit_token.path;
    in
      /*
      bash
      */
      ''
        [[ -z "$CONDUIT_CONFIG" ]] && exit 1
        [[ -f ${registrationSecretPath} ]] || exit 1
        CONF="$(mktemp)"
        chmod a-rwx "$CONF"
        chmod +rw "$CONF"

        function cleanup() {
          [[ -f "$CONF" ]] && rm "$CONF"
        }
        trap cleanup EXIT

        sed -e "s/__REGISTRATION_TOKEN__/$(cat ${registrationSecretPath})/g" "$CONDUIT_CONFIG" > "$CONF"
        CONDUIT_CONFIG="$CONF" conduit
      '';
  };
in {
  options.my.matrix = {
    enable = mkEnableOption "matrix conduit homeserver";
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

    supportEndpointJSON = mkOption {
      default = {};
      description = "JSON returned by /.well_known/matrix/support";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      conduit_token = {
        owner = wwwCfg.user;
        inherit (wwwCfg) group;
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

    # Overwrite module service configurations to allow for sops secrets
    systemd.services = {
      conduit.serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = lib.mkForce wwwCfg.user;
        ExecStart = lib.mkForce "${launchWithSecrets}/bin/launch-with-secrets";
        ProtectSystem = lib.mkForce "strict";
        ProtectHome = lib.mkForce "read-only";
        PrivateTmp = lib.mkForce true;
        RemoveIPC = lib.mkForce true;
      };

      heisenbridge = let
        pkg = pkgs.heisenbridge;
        bin = "${pkg}/bin/heisenbridge";

        registrationFile = "/var/lib/heisenbridge/registration.yml";
        # JSON is a proper subset of YAML
        bridgeConfig = builtins.toFile "heisenbridge-registration.yml" (builtins.toJSON {
          id = "heisenbridge";
          url = "http://localhost:${builtins.toString config.services.heisenbridge.port}";
          # Don't specify as_token and hs_token
          rate_limited = false;
          sender_localpart = "heisenbridge";
          namespaces = cfg.ircBridge.namespaces;
          media_url = "https://${wwwCfg.hostname}";
        });
      in
        lib.mkIf cfg.ircBridge.enable {
          description = "Matrix<->IRC bridge";
          before = ["conduit.service"]; # So the registration file can be used by Conduit
          wantedBy = ["multi-user.target"];

          preStart = ''
            umask 077
            set -e -u -o pipefail

            if ! [ -f "${registrationFile}" ]; then
              # Generate registration file if not present (actually, we only care about the tokens in it)
              ${bin} --generate --config ${registrationFile}
            fi

            # Overwrite the registration file with our generated one (the config may have changed since then),
            # but keep the tokens. Two step procedure to be failure safe
            ${pkgs.yq}/bin/yq --slurp \
              '.[0] + (.[1] | {as_token, hs_token})' \
              ${bridgeConfig} \
              ${registrationFile} \
              > ${registrationFile}.new
            mv -f ${registrationFile}.new ${registrationFile}
          '';

          serviceConfig = rec {
            Type = "simple";
            ExecStart = lib.concatStringsSep " " ([
                bin
                "-v"
                "--config"
                registrationFile
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

            User = wwwCfg.user;
            Group = wwwCfg.group;
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
    };

    services = {
      matrix-conduit = {
        enable = assert wwwCfg.blog; assert cfg.ircBridge.enable -> cfg.enable; true;
        settings.global = {
          inherit (cfg) port;
          server_name = hostname;
          allow_registration = true;
          registration_token = "__REGISTRATION_TOKEN__";
        };
      };

      nginx.virtualHosts.${hostname}.locations = let
        mkEndpoint = data: {
          extraConfig = ''
            default_type application/json;
            add_header Access-Control-Allow-Origin *;
            add_header Access-Control-Allow-Methods "GET, POST, DELETE, OPTIONS";
            add_header Access-Control-Allow-Headers "X-Requested-With, Content-Type, Authorization";
            return 200 '${builtins.toJSON data}';
          '';
        };
      in {
        "/_matrix/" = {
          proxyPass = "http://[::1]:${strPort}";
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header Access-Control-Allow-Origin *;
            proxy_set_header Access-Control-Allow-Methods "GET, POST, DELETE, OPTIONS";
            proxy_set_header Access-Control-Allow-Headers "X-Requested-With, Content-Type, Authorization";
            proxy_buffering on;
            proxy_read_timeout 5m;
          '';
        };

        "/.well-known/matrix/server" = mkEndpoint {"m.server" = "${hostname}:443";};
        "/.well-known/matrix/client" = mkEndpoint {
          "m.homeserver".base_url = "https://${hostname}";
          "org.matrix.msc3575.proxy".url = "https://${hostname}";
        };
        "/.well-known/matrix/support" = mkEndpoint cfg.supportEndpointJSON;
      };
    };

    networking.firewall = {
      allowedTCPPorts = optional cfg.ircBridge.identd.enable 113;
      allowedUDPPorts = optional cfg.ircBridge.identd.enable 113;
    };
  };
}
