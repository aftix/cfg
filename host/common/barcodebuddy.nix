{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  inherit (lib) mkDefault mkIf;
  inherit (lib.options) mkOption mkEnableOption;
  cfg = config.services.barcodebuddy;
in {
  options.services.barcodebuddy = {
    enable = mkEnableOption "barcodebuddy";

    enableWebsockets = mkOption {
      default = true;
      type = lib.types.bool;
    };

    user = mkOption {
      default = "barcodebuddy";
      type = lib.types.str;
    };

    group = mkOption {
      default = "barcodebuddy";
      type = lib.types.str;
    };

    phpfpm.settings = mkOption {
      type = with lib.types; attrsOf (oneOf [int str bool]);
      default = {
        "pm" = "dynamic";
        "php_admin_value[error_log]" = "stderr";
        "php_admin_flag[log_errors]" = true;
        "listen.owner" = cfg.user;
        "listen.group" = cfg.group;
        "catch_workers_output" = true;
        "pm.max_children" = "10";
        "pm.start_servers" = "2";
        "pm.min_spare_servers" = "2";
        "pm.max_spare_servers" = "4";
        "pm.max_requests" = "500";
      };

      description = ''
        Options for barcodebuddy's PHPFPM pool.
      '';
    };

    hostName = mkOption {
      default = "https://example.com";
      type = lib.types.str;
    };

    dataDir = mkOption {
      default = "/var/lib/barcodebuddy";
      type = lib.types.path;
    };

    acmeHost = mkOption {
      default = cfg.hostName;
      type = lib.types.str;
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [pkgs.barcodebuddy];

    nixpkgs.overlays = [
      (final: prev: {
        barcodebuddy-php = prev.php83.buildEnv {
          extensions = {
            enabled,
            all,
          }:
            enabled
            ++ (with all; [
              curl
              mbstring
              sqlite3
              redis
              sockets
            ]);
        };

        barcodebuddy = final.stdenv.mkDerivation rec {
          pname = "barcodebuddy";
          version = "1.8.1.7";

          src = inputs.barcodebuddy;

          nativeBuildInputs = with final; [
            barcodebuddy-php
            valkey
            evtest
          ];

          installPhase = ''
            runHook preInstall

            mkdir -p "$out"
            cp -R "${src}/"* "$out/."

            runHook postInstall
          '';
        };
      })
    ];

    security.acme.certs.${cfg.acmeHost} = mkIf (cfg.acmeHost != cfg.hostName) {
      extraDomainNames = [
        cfg.hostName
        ("www." + cfg.hostName)
      ];
    };

    systemd = {
      tmpfiles.rules = [
        "d '${cfg.dataDir}' - '${cfg.user}' '${cfg.group}' - -"
      ];

      services.barcodebuddy-wss = mkIf cfg.enableWebsockets {
        wants = ["network.target"];
        after = ["network.target"];
        wantedBy = ["multi-user.target"];
        unitConfig.Description = "Barcodebuddy for grocy - websocket server";

        serviceConfig = {
          User = cfg.user;
          Group = cfg.group;
          WorkingDirectory = pkgs.barcodebuddy;
          ProtectSystem = "strict";
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectHome = "read-only";
          NoNewPrivileges = true;
          ReadWritePaths = cfg.dataDir;
          MemoryDenyWriteExecute = true;
        };

        script = let
          inherit (lib.strings) escapeShellArg;
        in ''
          export BBUDDY_CONFIG_PATH=${escapeShellArg cfg.dataDir}/config.php
          export BBUDDY_LEGACY_DATABASE_PATH=${escapeShellArg cfg.dataDir}/barcodebuddy_legacy.db
          export BBUDDY_DATABASE_PATH=${escapeShellArg cfg.dataDir}/barcodebuddy.db
          export BBUDDY_AUTHDB_PATH=${escapeShellArg cfg.dataDir}/auth.db
          ${config.services.phpfpm.pools.barcodebuddy.phpPackage}/bin/php wsserver.php
        '';
      };
    };

    networking.firewall = mkIf cfg.enableWebsockets {
      allowedTCPPorts = [47631];
      allowedUDPPorts = [47631];
    };

    services = {
      phpfpm.pools.barcodebuddy = {
        inherit (cfg) user group;
        inherit (cfg.phpfpm) settings;
        phpPackage = pkgs.barcodebuddy-php;
      };

      nginx = {
        enable = true;
        virtualHosts.${cfg.hostName} = {
          root = pkgs.barcodebuddy;
          serverName = mkDefault "${cfg.hostName} www.${cfg.hostName}";
          kTLS = mkDefault true;
          forceSSL = mkDefault true;
          useACMEHost = mkDefault cfg.acmeHost;

          extraConfig = ''
            index index.php index.html index.htm;
            client_max_body_size 20M;
            client_body_buffer_size 128k;
          '';

          locations = {
            "/".tryFiles = "$uri $uri/ =404";
            "/api/".tryFiles = "$uri /api/index.php$is_args$query_string";

            "~ /example/".extraConfig = ''
              deny all;
            '';
            "~ /data/".extraConfig = ''
              deny all;
            '';
            "~ /\\.ht".extraConfig = ''
              deny all;
            '';

            "~ \\.php$".extraConfig = ''
              fastcgi_read_timeout 80;
              include ${config.services.nginx.package}/conf/fastcgi.conf;
              include ${config.services.nginx.package}/conf/fastcgi_params;
              fastcgi_param BBUDDY_CONFIG_PATH '${cfg.dataDir}/config.php';
              fastcgi_param BBUDDY_LEGACY_DATABASE_PATH '${cfg.dataDir}/barcodebuddy_legacy.db';
              fastcgi_param BBUDDY_DATABASE_PATH '${cfg.dataDir}/barcodebuddy.db';
              fastcgi_param BBUDDY_AUTHDB_PATH '${cfg.dataDir}/auth.db';
              fastcgi_param BBUDDY_HIDE_LINK_SCREEN 'true';
              fastcgi_pass unix:${config.services.phpfpm.pools.barcodebuddy.socket};
            '';
          };
        };
      };
    };
  };
}
