{
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf mkDefault;
  cfg = config.my.www;
in {
  options.my.www.coffeepasteLocation = lib.options.mkOption {
    default = "file";
    type = lib.types.str;
  };

  config = mkIf config.services.coffeepaste.enable {
    services = {
      coffeepaste = {
        user = mkDefault cfg.user;
        group = mkDefault cfg.group;
        url = mkDefault "https://${cfg.hostname}/${cfg.coffeepasteLocation}";
      };

      nginx = {
        upstreams = {
          coffeepaste = {
            servers."localhost:${builtins.toString config.services.coffeepaste.listenPort}" = {};
            extraConfig = ''
              zone coffeepaste 64k;
              keepalive 8;
            '';
          };
        };

        virtualHosts.${cfg.hostname} = {
          locations = assert config.services.coffeepaste.enable -> cfg.blog; {
            "/${cfg.coffeepasteLocation}/" = {
              proxyPass = "http://coffeepaste/";
              extraConfig = ''
                if ($request_method = PUT) {
                  return ${builtins.toString cfg.putRequestCode};
                }
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
              '';
            };

            "@putrequest" = {
              proxyPass = "http://coffeepaste";
              extraConfig = ''
                limit_req zone=put_request_by_addr burst=10;
                proxy_pass_request_headers on;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
              '';
            };
          };
        };
      };
    };
  };
}
