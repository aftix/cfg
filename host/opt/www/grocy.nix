{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkForce;
  inherit (lib.options) mkOption mkEnableOption;
  wwwCfg = config.my.www;
  cfg = wwwCfg.grocy;

  acmeHost =
    if cfg.acmeDomain == null
    then cfg.domain
    else cfg.acmeDomain;
in {
  options.my.www.grocy = {
    enable = mkEnableOption "grocy";

    domain = mkOption {
      type = lib.types.str;
    };

    acmeDomain = mkOption {
      default = wwwCfg.acmeDomain;
      type = with lib.types; nullOr str;
      description = "null to use \${my.www.grocy.domain}";
    };

    phpfpm.settings = mkOption {
      type = with lib.types; attrsOf (oneOf [int str bool]);
      default = {
        "pm" = "dynamic";
        "php_admin_value[error_log]" = "stderr";
        "php_admin_flag[log_errors]" = true;
        "listen.owner" = "grocy";
        "listen.group" = "grocy";
        "listen.mode" = "0666";
        "catch_workers_output" = true;
        "pm.max_children" = "32";
        "pm.start_servers" = "2";
        "pm.min_spare_servers" = "2";
        "pm.max_spare_servers" = "4";
        "pm.max_requests" = "500";
      };
      description = ''
        Options for grocy's PHPFPM pool.
      '';
    };

    settings = {
      currency = mkOption {
        default = "USD";
        type = lib.types.str;
        example = "EUR";
        description = ''
          ISO 4217 code for the currency to display.
        '';
      };

      culture = mkOption {
        default = "en";
        type = lib.types.enum ["de" "en" "da" "en_GB" "es" "fr" "hu" "it" "nl" "no" "pl" "pt_BR" "ru" "sk_SK" "sv_SE" "tr"];
        description = ''
          Display language of the frontend.
        '';
      };

      calendar = {
        showWeekNumber = mkOption {
          default = true;
          type = lib.types.bool;
          description = ''
            Show the number of the weeks in the calendar views.
          '';
        };
        firstDayOfWeek = mkOption {
          default = null;
          type = lib.types.nullOr (lib.types.enum (lib.range 0 6));
          description = ''
            Which day of the week (0=Sunday, 1=Monday etc.) should be the
            first day.
          '';
        };
      };
    };
  };

  config = mkIf cfg.enable {
    environment = {
      etc."grocy/config.php".text =
        /*
        php
        */
        ''
               <?php
          Setting('CULTURE', '${cfg.settings.culture}');
          Setting('CURRENCY', '${cfg.settings.currency}');
          Setting('CALENDAR_FIRST_DAY_OF_WEEK', '${builtins.toString cfg.settings.calendar.firstDayOfWeek}');
          Setting('CALENDAR_SHOW_WEEK_OF_YEAR', ${lib.boolToString cfg.settings.calendar.showWeekNumber});
        '';

      systemPackages = [pkgs.grocy];
    };

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

    systemd = {
      tmpfiles.settings."10-grocy" = let
        dirRule = {
          user = "grocy";
          group = "grocy";
        };

        dirLst = [
          ""
          "/viewcache"
          "/plugins"
          "/settingoverrides"
          "/storage"
        ];
      in
        lib.pipe dirLst [
          (builtins.map (name: "/var/lib/grocy${name}"))
          (builtins.map (dirName: {
            ${dirName} = {
              d = dirRule;
              Z = dirRule;
            };
          }))
          lib.attrsets.mergeAttrsList
        ];

      services = {
        grocy-setup = {
          wantedBy = ["multi-user.target"];
          before = ["phpfpm-grocy.service"];
          serviceConfig =
            config.my.systemdHardening
            // {
              User = mkForce "grocy";
              Group = mkForce "grocy";
              WorkingDirectory = config.services.grocy.package;
              StateDirectory = "grocy";

              PrivateNetwork = true;
            };
          script = ''
            rm -rf "$STATE_DIRECTORY"/viewcache/*
          '';
        };

        phpfpm-grocy.serviceConfig = config.my.hardenPHPFPM {
          workdir = config.services.grocy.package;
          datadir = "/var/lib/grocy";
        };
      };
    };

    services = {
      phpfpm.pools.grocy = {
        user = "grocy";
        group = "grocy";
        inherit (cfg.phpfpm) settings;
        phpPackage = pkgs.php82;
        phpEnv = {
          GROCY_CONFIG_FILE = "/etc/grocy/config.php";
          GROCY_DB_FILE = "/var/lib/grocy/grocy.db";
          GROCY_STORAGE_DIR = "/var/lib/grocy/storage";
          GROCY_PLUGIN_DIR = "/var/lib/grocy/plugins";
          GROCY_CACHE_DIR = "/var/lib/grocy/viewcache";
        };
      };

      nginx = {
        enable = true;

        upstreams.grocy = {
          servers."unix:${config.services.phpfpm.pools.grocy.socket}" = {};
          extraConfig = ''
            keepalive 8;
          '';
        };

        virtualHosts.${cfg.domain} = {
          root = "${pkgs.grocy}/public";
          serverName = "${cfg.domain} www.${cfg.domain}";
          kTLS = true;
          forceSSL = true;
          useACMEHost = acmeHost;

          extraConfig = ''
            try_files $uri /index.php;
            include /etc/nginx/bots.d/blockbots.conf;
            include /etc/nginx/bots.d/ddos.conf;
          '';

          locations = {
            "/".extraConfig = ''
              rewrite ^ /index.php;
            '';

            "~ \\.php$".extraConfig = ''
              fastcgi_split_path_info ^(.+\.php)(/.+)$;
              fastcgi_pass grocy;
              fastcgi_keep_conn on;
              include ${config.services.nginx.package}/conf/fastcgi.conf;
              include ${config.services.nginx.package}/conf/fastcgi_params;
            '';

            "~ \\.(js|css|ttf|woff2?|png|jpe?g|svg)$".extraConfig = ''
              add_header Cache-Control "public, max-age=15778463";
              add_header X-Content-Type-Options nosniff;
              add_header X-XSS-Protection "1; mode=block";
              add_header X-Robots-Tag none;
              add_header X-Download-Options noopen;
              add_header X-Permitted-Cross-Domain-Policies none;
              add_header Referrer-Policy no-referrer;
              access_log off;
            '';
          };
        };
      };
    };

    users = {
      users.grocy = {
        group = "grocy";
        isSystemUser = true;
        shell = lib.getExe' pkgs.util-linux "nologin";
      };

      groups.grocy = {};
    };
  };
}
