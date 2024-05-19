{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault mkIf mkForce;
  inherit (lib.options) mkOption mkEnableOption;
  wwwCfg = config.my.www;
  cfg = wwwCfg.grocy;
in {
  options.my.www.grocy = {
    enable = mkEnableOption "grocy";

    subdomain = mkOption {
      default = "grocy";
      type = lib.types.str;
    };

    user = mkOption {
      default = wwwCfg.user;
    };

    group = mkOption {
      default = wwwCfg.group;
    };

    phpfpm.settings = mkOption {
      type = with lib.types; attrsOf (oneOf [int str bool]);
      default = {
        "pm" = "dynamic";
        "php_admin_value[error_log]" = "stderr";
        "php_admin_flag[log_errors]" = true;
        "listen.owner" = cfg.user;
        "listen.group" = cfg.group;
        "listen.mode" = "0600";
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

    dataDir = mkOption {
      default = "/var/lib/grocy";
      type = lib.types.str;
      description = ''
        Home directory of the `grocy` user which contains
        the application's state.
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
      etc."grocy/config.php".text = ''
             <?php
        Setting('CULTURE', '${cfg.settings.culture}');
        Setting('CURRENCY', '${cfg.settings.currency}');
        Setting('CALENDAR_FIRST_DAY_OF_WEEK', '${builtins.toString cfg.settings.calendar.firstDayOfWeek}');
        Setting('CALENDAR_SHOW_WEEK_OF_YEAR', ${lib.boolToString cfg.settings.calendar.showWeekNumber});
      '';

      systemPackages = [pkgs.grocy];
    };

    users = {
      users.${cfg.user} = mkIf (cfg.user != wwwCfg.user) {
        isSystemUser = mkDefault true;
        createHome = mkDefault true;
        home = mkDefault cfg.dataDir;
        group = mkDefault cfg.group;
      };

      groups.${cfg.group} =
        mkIf (cfg.group != wwwCfg.group) {
        };
    };

    security.acme.certs.${wwwCfg.hostname}.extraDomainNames = [
      "${cfg.subdomain}.${wwwCfg.hostname}"
      "www.${cfg.subdomain}.${wwwCfg.hostname}"
    ];

    systemd = {
      tmpfiles.rules =
        ["d '${cfg.dataDir}' - ${cfg.user} ${cfg.group} - -"]
        ++ (map (dirName: "d '${cfg.dataDir}/${dirName}' - ${cfg.user} ${cfg.group} - -") [
          "viewcache"
          "plugins"
          "settingoverrides"
          "storage"
        ]);

      services = {
        grocy-setup = {
          wantedBy = ["multi-user.target"];
          before = ["phpfpm-grocy.service"];
          serviceConfig =
            config.my.systemdHardening
            // {
              User = mkForce cfg.user;
              Group = mkForce cfg.group;
              WorkingDirectory = cfg.dataDir;
              ReadWritePaths = cfg.dataDir + "/viewcache";

              PrivateNetwork = true;
            };
          script = ''
            rm -rf ${lib.strings.escapeShellArg cfg.dataDir}/viewcache/*
          '';
        };

        phpfpm-grocy.serviceConfig = config.my.hardenPHPFPM {
          workdir = config.services.grocy.package;
          datadir = cfg.dataDir;
        };
      };
    };

    services = {
      phpfpm.pools.grocy = {
        inherit (cfg) user group;
        inherit (cfg.phpfpm) settings;
        phpPackage = pkgs.php82;
        phpEnv = {
          GROCY_CONFIG_FILE = "/etc/grocy/config.php";
          GROCY_DB_FILE = "${cfg.dataDir}/grocy.db";
          GROCY_STORAGE_DIR = "${cfg.dataDir}/storage";
          GROCY_PLUGIN_DIR = "${cfg.dataDir}/plugins";
          GROCY_CACHE_DIR = "${cfg.dataDir}/viewcache";
        };
      };

      nginx.virtualHosts."${cfg.subdomain}.${wwwCfg.hostname}" = {
        root = "${pkgs.grocy}/public";
        serverName = "${cfg.subdomain}.${wwwCfg.hostname} www.${cfg.subdomain}.${wwwCfg.hostname}";
        kTLS = true;
        forceSSL = true;
        useACMEHost = wwwCfg.hostname;

        extraConfig = ''
          try_files $uri /index.php;
        '';

        locations = {
          "/".extraConfig = ''
            rewrite ^ /index.php;
          '';

          "~ \\.php$".extraConfig = ''
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass unix:${config.services.phpfpm.pools.grocy.socket};
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
}
