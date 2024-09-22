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

      nginx.virtualHosts.${cfg.hostname} = {
        locations = assert config.services.coffeepaste.enable -> cfg.blog; {
          "/${cfg.coffeepasteLocation}/" = {
            proxyPass = "http://localhost:${builtins.toString config.services.coffeepaste.listenPort}/";
            extraConfig = ''
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            '';
          };

          "@putrequest" = {
            proxyPass = "http://localhost:${builtins.toString config.services.coffeepaste.listenPort}";
            extraConfig = ''
              if ($request_method = PUT) {
                return ${builtins.toString cfg.putRequestCode};
              }

              limit_req zone=put_request_by_addr burst=10;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            '';
          };
        };
      };
    };
  };
}
