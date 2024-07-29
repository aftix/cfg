{
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf mkDefault;
  cfg = config.my.www;
in {
  options.my.www.coffeepasteSubdomain = lib.options.mkOption {
    default = "file";
    type = lib.types.str;
  };

  config = mkIf config.services.coffeepaste.enable {
    security.acme.certs.${cfg.hostname}.extraDomainNames = [
      "${cfg.coffeepasteSubdomain}.${cfg.hostname}"
      "www.${cfg.coffeepasteSubdomain}.${cfg.hostname}"
    ];

    services = {
      coffeepaste = {
        user = mkDefault cfg.user;
        group = mkDefault cfg.group;
        url = mkDefault "https://${cfg.coffeepasteSubdomain}.${cfg.hostname}";
      };

      nginx.virtualHosts."${cfg.coffeepasteSubdomain}.${cfg.hostname}" = {
        serverName = "${cfg.coffeepasteSubdomain}.${cfg.hostname} www.${cfg.coffeepasteSubdomain}.${cfg.hostname}";
        kTLS = true;
        forceSSL = true;
        useACMEHost = cfg.hostname;

        extraConfig = ''
          error_page 599 = @putrequest;
          if ($request_method = 'PUT') {
            return 599;
          }
          include /etc/nginx/bots.d/blockbots.conf;
          include /etc/nginx/bots.d/ddos.conf;
        '';

        locations = {
          "/" = {
            proxyPass = "http://localhost:${builtins.toString config.services.coffeepaste.listenPort}";
            extraConfig = ''
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            '';
          };

          "@putrequest" = {
            proxyPass = "http://localhost:${builtins.toString config.services.coffeepaste.listenPort}";
            extraConfig = ''
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
