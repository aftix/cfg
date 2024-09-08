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
    in ''
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
    sops.secrets.conduit_token = {
      owner = wwwCfg.user;
      inherit (wwwCfg) group;
    };

    systemd.services.conduit.serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = lib.mkForce wwwCfg.user;
      ExecStart = lib.mkForce "${launchWithSecrets}/bin/launch-with-secrets";
      ProtectSystem = lib.mkForce "strict";
      ProtectHome = lib.mkForce "read-only";
      PrivateTmp = lib.mkForce true;
      RemoveIPC = lib.mkForce true;
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
  };
}
