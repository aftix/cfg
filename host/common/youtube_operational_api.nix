{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.youtube-operational-api;

  inherit (lib.options) mkOption mkEnableOption mkPackageOption;
  inherit (lib.attrsets) mapAttrsToList optionalAttrs;

  mkConfigValue = x:
    if builtins.isString x
    then "'${x}'"
    else if builtins.isPath x
    then "'${builtins.toString x}'"
    else if builtins.isBool x
    then
      (
        if x
        then "True"
        else "False"
      )
    else if builtins.isList x
    then "[${lib.strings.concatStringsSep " " (builtins.map mkConfigValue x)}]"
    else if builtins.isInt x
    then "${builtins.toString x}"
    else "'${builtins.toString x}'";
  mkConfigDefine = name: x: "define('${name}', ${mkConfigValue x});";
  mkConfig = attrs: ''
    <?php
    ${lib.strings.concatLines (mapAttrsToList mkConfigDefine attrs)}
    ?>
  '';

  defaultSettings = {
    SERVER_NAME = "localhost";
    GOOGLE_ABUSE_EXEMPTION = "";
    MULTIPLE_IDS_ENABLED = true;
    HTTPS_PROXY_ADDRESS = "";
    HTTPS_PROXY_PORT = 80;
    HTTPS_PROXY_USERNAME = "";
    HTTPS_PROXY_PASSWORD = "";
    RESTRICT_USAGE_TO_KEY = "";
    ADD_KEY_FORCE_SECRET = "";
    ADD_KEY_TO_INSTANCES = [];
  };
  settings = defaultSettings // (optionalAttrs (cfg.settings != null) cfg.settings) // {KEYS_FILE = cfg.keysFile;};

  defaultUser = "youtubeapi";

  cfgPackage =
    pkgs.runCommandWith {
      name = "youtube-operational-api-configured";
      stdenv = pkgs.stdenvNoCC;
      runLocal = true;
      derivationArgs.overrideConfig = pkgs.writeText "youtubeapi-configuration.php" (mkConfig settings);
    } ''
      mkdir -p $out
      cp -vr "${cfg.package}/"* $out/
      rm $out/configuration.php
      cp $overrideConfig $out/configuration.php
    '';
in {
  options.services.youtube-operational-api = {
    enable = mkEnableOption "Youtube operational API";
    package = mkPackageOption pkgs "youtube-operational-api" {};

    settings = mkOption {
      default = null;
      description = "Settings for the configuration.php file.";
      type = with lib.types; nullOr (attrsOf str);
    };

    keysFile = mkOption {
      default = "/dev/null";
      description = "File containing API keys for youtube.";
      type = lib.types.nonEmptyStr;
    };

    user = mkOption {
      default = defaultUser;
      description = "User to run the service under, will be created if ${defaultUser}";
      type = lib.types.nonEmptyStr;
    };

    group = mkOption {
      default = defaultUser;
      description = "Group to run the service under, will be created if ${defaultUser}";
      type = lib.types.nonEmptyStr;
    };

    port = mkOption {
      default = 9575;
      description = "Port to listen on for docker container";
      type = lib.types.ints.positive;
    };

    pool = mkOption {
      default = "youtubeapi";
      description = "Name of phpfpm pool to run under";
      type = lib.types.nonEmptyStr;
    };
  };

  config = lib.mkIf cfg.enable {
    users = {
      users.${defaultUser} = lib.mkIf (cfg.user == defaultUser) {
        inherit (cfg) group;
        shell = "/run/current-system/sw/bin/nologin";
        isSystemUser = true;
        description = "youtube-operational-api service user";
        home = "/var/empty";
      };

      groups.${defaultUser} = lib.mkIf (cfg.group == defaultUser) {};
    };

    services = {
      phpfpm.pools.${cfg.pool} = {
        inherit (cfg) user group;
        phpPackage = pkgs.php82;
        settings = {
          "listen.owner" = cfg.user;
          "listen.group" = cfg.group;
          "listen.mode" = "0600";
          pm = "dynamic";
          "pm.max_children" = 32;
          "pm.max_requests" = 500;
          "pm.start_servers" = 2;
          "pm.min_spare_servers" = 2;
          "pm.max_spare_servers" = 5;
          "catch_workers_output" = true;
        };
      };

      nginx = {
        enable = true;

        virtualHosts.youtubeapi = {
          root = cfgPackage;
          rejectSSL = true;
          serverName = "localhost";

          listen = [
            {
              inherit (cfg) port;
              addr = "127.0.0.1";
            }
            {
              inherit (cfg) port;
              addr = "[::1]";
            }
          ];

          extraConfig = ''
            index index.php index.html index.htm;
            rewrite ^/(search|videos|playlists|playlistItems|channels|community|webhooks|commentThreads|lives|liveChats)$ /$1.php;
            rewrite ^/noKey/ /noKey/index.php;
          '';

          locations = {
            "/" = {
              tryFiles = "$uri $uri/ index.php";
              index = "index.php index.html index.htm";
            };

            "= /ytPrivate/keys.txt".extraConfig = "deny all;";
            "~ /noKey".extraConfig = "rewrite ^(.*)$ /noKey/index.php;";
            "~ ^.+?\.php(/.*)?$".extraConfig = ''
              fastcgi_pass unix:${config.services.phpfpm.pools.${cfg.pool}.socket};
              fastcgi_split_path_info ^(.+\.php)(/.*)$;
              set $path_info $fastcgi_path_info;
              fastcgi_param PATH_INFO $path_info;
              fastcgi_read_timeout 80;
              fastcgi_keep_conn on;
              include ${config.services.nginx.package}/conf/fastcgi.conf;
              include ${config.services.nginx.package}/conf/fastcgi_params;
            '';
          };
        };
      };
    };
  };
}
