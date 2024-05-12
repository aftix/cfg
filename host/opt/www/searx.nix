{
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf mkForce;
  inherit (lib.options) mkOption mkEnableOption;
  wwwCfg = config.my.www;
  cfg = wwwCfg.searx;
  socket = "/run/uwsgi/app/searx/socket";
in {
  options.my.www.searx = {
    enable = mkEnableOption "searx";
    subdomain = mkOption {
      default = "searx";
      type = lib.types.str;
    };
  };

  config = mkIf cfg.enable {
    sops = {
      secrets."searx_key" = {};
      templates."searx.env".content = ''
        SEARX_SECRET_KEY=${lib.strings.escapeShellArg config.sops.placeholder.searx_key}
      '';
    };

    users.users.searx.extraGroups = [wwwCfg.group];

    security.acme.certs.${wwwCfg.hostname}.extraDomainNames = [
      "${cfg.subdomain}.${wwwCfg.hostname}"
      "www.${cfg.subdomain}.${wwwCfg.hostname}"
    ];

    systemd.tmpfiles.rules = let
      inherit (config.services.searx.uwsgiConfig) immediate-uid immediate-gid;
    in [
      "d /run/uwsgi 0775 ${immediate-uid} ${immediate-gid} -"
      "d /run/uwsgi/app 0775 ${immediate-uid} ${immediate-gid} -"
      "d /run/uwsgi/app/searx 0775 ${immediate-uid} ${immediate-gid} -"
    ];

    environment.etc."nginx/uwsgi_params".text = ''
      uwsgi_param  QUERY_STRING       $query_string;
      uwsgi_param  REQUEST_METHOD     $request_method;
      uwsgi_param  CONTENT_TYPE       $content_type;
      uwsgi_param  CONTENT_LENGTH     $content_length;

      uwsgi_param  REQUEST_URI        $request_uri;
      uwsgi_param  PATH_INFO          $document_uri;
      uwsgi_param  DOCUMENT_ROOT      $document_root;
      uwsgi_param  SERVER_PROTOCOL    $server_protocol;
      uwsgi_param  REQUEST_SCHEME     $scheme;
      uwsgi_param  HTTPS              $https if_not_empty;

      uwsgi_param  REMOTE_ADDR        $remote_addr;
      uwsgi_param  REMOTE_PORT        $remote_port;
      uwsgi_param  SERVER_PORT        $server_port;
      uwsgi_param  SERVER_NAME        $server_name;
    '';

    systemd.services.searx-init.serviceConfig.User = mkForce config.services.searx.uwsgiConfig.immediate-uid;

    services = {
      nginx.virtualHosts."${cfg.subdomain}.${wwwCfg.hostname}" = {
        root = "${config.services.searx.package}/share";
        serverName = "${cfg.subdomain}.${wwwCfg.hostname} www.${cfg.subdomain}.${wwwCfg.hostname}";
        kTLS = true;
        forceSSL = true;
        useACMEHost = wwwCfg.hostname;

        locations =
          {
            "/".extraConfig = ''
              include uwsgi_params;
              uwsgi_pass unix:${socket};
            '';

            "/static/".alias = "${config.services.searx.package}/share/static";
          }
          // wwwCfg.acme-location-block;
      };

      redis.servers.searx.user = mkForce config.services.searx.uwsgiConfig.immediate-uid;

      uwsgi = {
        user = mkForce config.services.searx.uwsgiConfig.immediate-uid;
        group = mkForce config.services.searx.uwsgiConfig.immediate-gid;
      };

      searx = {
        enable = true;
        runInUwsgi = true;
        redisCreateLocally = true;

        environmentFile = config.sops.templates."searx.env".path;

        settings = {
          use_default_settings = mkForce false;
          instance_name = "searx";
          contact_url = "mailto:aftix@aftix.xyz";
          server = {
            secret_key = "@SEARX_SECRET_KEY@";
            base_url = "${cfg.subdomain}.${wwwCfg.hostname}";
            image_proxy = true;
          };
        };

        uwsgiConfig = {
          inherit socket;
          chmod-socket = "660";
          immediate-uid = wwwCfg.user;
          immediate-gid = wwwCfg.group;

          env = [
            "SEARX_SETTINGS_PATH=${config.services.searx.settingsFile}"
            "SEARXNG_SETTINGS_PATH=${config.services.searx.settingsFile}"
            "LANG=C.UTF-8"
            "LANGUAGE=C.UTF-8"
            "LC_ALL=C.UTF-8"
          ];

          single-interpreter = true;
          master = true;
          lazy-apps = true;
          enable-threads = true;
          cache2 = "name=searxcache,items=2000,blocks=2000,blocksize=4096,bitmap=1";
        };
      };
    };
  };
}
