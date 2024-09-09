{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.strings) escapeShellArg;

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

  ircBridgeConfigFile =
    pkgs.runCommand "matrix-appservice-irc.yml" {
      # Because this program will be run at build time, we need `nativeBuildInputs`
      nativeBuildInputs = [(pkgs.python3.withPackages (ps: [ps.jsonschema])) pkgs.remarshal];
      preferLocalBuild = true;

      config = builtins.toJSON config.services.matrix-appservice-irc.settings;
      passAsFile = ["config"];
    }
    /*
    bash
    */
    ''
      # The schema is given as yaml, we need to convert it to json
      remarshal --if yaml --of json -i ${pkgs.matrix-appservice-irc}/config.schema.yml -o config.schema.json
      python -m jsonschema config.schema.json -i $configPath
      cp "$configPath" "$out"
    '';
  launchBridgeWithSecrets = pkgs.writeShellApplication {
    name = "launch-bridge-with-secrets";
    runtimeInputs = with pkgs; [gnused coreutils-full matrix-appservice-irc];
    text = let
      esperNickservSecretPath = escapeShellArg config.sops.secrets.esper_nickserv_password.path;
    in
      /*
      bash
      */
      ''
        CONF="$(mktemp)"
        chmod a-rwx "$CONF"
        chmod +rw "$CONF"

        function cleanup() {
          [[ -f "$CONF" ]] && rm "$CONF"
        }
        trap cleanup EXIT

        sed -e "s/__ESPER_PASSWORD__/$(cat ${esperNickservSecretPath})/g" ${ircBridgeConfigFile} > "$CONF"
        matrix-appservice-irc --config "$CONF" --file /var/lib/matrix-appservice-irc/registration.yml --port ${builtins.toString config.services.matrix-appservice-irc.port}
      '';
  };
in {
  options.my.matrix = {
    enable = mkEnableOption "matrix conduit homeserver";
    ircBridge = {
      enable = mkEnableOption "matrix-appservice-irc bridge";

      mediaProxyPort = mkOption {
        default = 9000;
        type = lib.types.ints.positive;
      };

      esper = mkEnableOption "espernet irc bridge";
      esperPort = mkOption {
        default = 9091;
        type = lib.types.ints.positive;
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

      esper_nickserv_password = rec {
        owner = "matrix-appservice-irc";
        group = owner;
      };
    };

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

      matrix-appservice-irc.serviceConfig.ExecStart = lib.mkForce "${launchBridgeWithSecrets}/bin/launch-bridge-with-secrets";
    };

    services = {
      matrix-conduit = {
        enable = assert wwwCfg.blog; true;
        settings.global = {
          inherit (cfg) port;
          server_name = hostname;
          allow_registration = true;
          registration_token = "__REGISTRATION_TOKEN__";
        };
      };

      matrix-appservice-irc = {
        enable = assert cfg.ircBridge.enable -> cfg.enable; cfg.ircBridge.enable;

        registrationUrl = "http://localhost:${builtins.toString config.services.matrix-appservice-irc.port}";

        settings = rec {
          homeserver = {
            url = "http://localhost:${builtins.toString cfg.port}";
            domain = config.services.matrix-conduit.settings.global.server_name;
          };
          ircService = {
            permissions = {
              "@admin:${homeserver.domain}" = "admin";
              "@aftix:matrix.org" = "admin";
            };

            mediaProxy = {
              enable = true;
              bindPort = cfg.ircBridge.mediaProxyPort;
              publicUrl = "${homeserver.url}/_media";
            };

            servers = lib.mkMerge [
              (lib.mkIf cfg.ircBridge.esper {
                "irc.esper.net" = {
                  name = "EsperNet";
                  port = 6697;
                  ssl = true;
                  sasl = true;
                  botConfig = {
                    nick = "AftMatrixBot";
                    username = "aftixmatrixbridge";
                    password = "__ESPER_PASSWORD__";
                  };

                  ircClients.nickTemplate = "$DISPLAY[m]";
                };
              })
            ];
          };
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
      in
        lib.mkMerge [
          {
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
          }
          (lib.mkIf cfg.ircBridge.esper {
            "/_media/" = {
              proxyPass = "http://127.0.0.1:${builtins.toString cfg.ircBridge.mediaProxyPort}/";
              extraConfig = ''
                proxy_set_header X-Forwarded-For $remote_addr;
              '';
            };
          })
        ];
    };
  };
}
