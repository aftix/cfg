{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  inherit (lib.attrsets) filterAttrs;
  inherit (lib.options) mkOption mkEnableOption;

  wwwCfg = config.my.www;
  cfg = config.my.www.barcodebuddy;

  acmeHost =
    if cfg.acmeDomain == null
    then cfg.domain
    else cfg.acmeDomain;
in {
  options.my.www.barcodebuddy = {
    enable = mkEnableOption "barcodebuddy";

    domain = mkOption {
      type = lib.types.str;
    };

    acmeDomain = mkOption {
      default = wwwCfg.acmeDomain;
      type = with lib.types; nullOr str;
      description = "null to use \${my.www.grocy.domain}";
    };

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
        "listen.mode" = "0666";
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

    dataDir = mkOption {
      default = "/var/lib/barcodebuddy";
      type = lib.types.path;
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

    networking.firewall = mkIf cfg.enableWebsockets {
      allowedTCPPorts = [47631];
      allowedUDPPorts = [47631];
    };

    services = {
      phpfpm.pools.barcodebuddy = {
        inherit (cfg) user group;
        inherit (cfg.phpfpm) settings;
        phpPackage = pkgs.barcodebuddy.phpWithExts;
      };

      nginx = {
        enable = true;

        upstreams.barcodebuddy = {
          servers."unix:${config.services.phpfpm.pools.barcodebuddy.socket}" = {};
          extraConfig = ''
            keepalive 8;
          '';
        };

        virtualHosts.${cfg.domain} = {
          root = pkgs.barcodebuddy;
          serverName = "${cfg.domain} www.${cfg.domain}";
          kTLS = true;
          forceSSL = true;
          useACMEHost = cfg.acmeDomain;

          extraConfig = ''
            index index.php index.html index.htm;
            client_max_body_size 20M;
            client_body_buffer_size 128k;
            include /etc/nginx/bots.d/blockbots.conf;
            include /etc/nginx/bots.d/ddos.conf;
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
              fastcgi_keep_conn on;
              fastcgi_pass barcodebuddy;
            '';
          };
        };
      };
    };

    systemd = {
      tmpfiles.settings."10-bbuddy".${cfg.dataDir}.d = {
        inherit (cfg) user group;
      };

      services = {
        phpfpm-barcodebuddy.serviceConfig = filterAttrs (n: v: !builtins.elem n ["IPAddressAllow" "IPAddressDeny"]) (config.my.hardenPHPFPM {
          workdir = pkgs.barcodebuddy;
          datadir = cfg.dataDir;
        });

        barcodebuddy-wss = mkIf cfg.enableWebsockets {
          wants = ["network.target"];
          after = ["network.target"];
          wantedBy = ["multi-user.target"];
          unitConfig.Description = "Barcodebuddy for grocy - websocket server";

          serviceConfig =
            (filterAttrs (n: v: !builtins.elem n ["IPAddressAllow" "IPAddressDeny"]) config.my.systemdHardening)
            // {
              User = cfg.user;
              Group = cfg.group;
              WorkingDirectory = pkgs.barcodebuddy;

              PrivateTmp = true;
              ReadWritePaths = cfg.dataDir;
              MemoryDenyWriteExecute = false;
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
    };

    users = {
      users.barcodebuddy = {
        group = "barcodebuddy";
        isSystemUser = true;
        shell = lib.getExe' pkgs.util-linux "nologin";
      };

      groups.barcodebuddy = {};
    };
  };
}
