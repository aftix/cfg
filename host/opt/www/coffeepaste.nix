{
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf;
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.options) mkOption mkEnableOption;
  wwwCfg = config.my.www;
  cfg = config.my.www.coffeepaste;

  acmeHost =
    if cfg.acmeDomain == null
    then cfg.domain
    else cfg.acmeDomain;
in {
  options.my.www.coffeepaste = {
    enable = mkEnableOption "coffeepaste";

    domain = mkOption {
      default = null;
      type = with lib.types; nullOr str;
      description = ''
        Domain to host coffeepaste under.

        Exactly one of ''${my.www.coffeepaste.domain}
        or ''${my.www.coffeepaste.virtualHost} must
        be non-null if ''${my.www.coffeepaste.enable}
        is true.
      '';
    };

    acmeDomain = mkOption {
      default = wwwCfg.acmeDomain;
      type = with lib.types; nullOr str;
      description = ''
        Used if ''${my.www.coffeepaste.domain} is non-null.

        If non-null, use as the ACME host;
        otherwise, use ''${my.www.coffeepaste.domain} as the
        ACME host.
      '';
    };

    virtualHost = mkOption {
      default = null;
      type = with lib.types; nullOr str;
      description = ''
        If non-null, nginx virtual host to add ''${my.www.coffeepaste.location}
        redirect under.

        Exactly one of ''${my.www.coffeepaste.domain}
        or ''${my.www.coffeepaste.virtualHost} must
        be non-null if ''${my.www.coffeepaste.enable}
        is true.
      '';
    };

    location = lib.options.mkOption {
      default = null;
      type = with lib.types; nullOr str;
      description = ''
        Subpath under ''${my.www.coffeepaste.virtualHost}
        to host coffeepaste. Must be non-null if ''${my.www.coffeepaste.virtualHost}
        is non-null.
      '';
    };

    putRequestCode = mkOption {
      default = 599;
      type = lib.types.ints.positive;
      description = ''
        Placeholder HTTP status code to use
        for nginx to limit the upload size.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = (cfg.domain != null) || (cfg.virtualHost != null);
        message = ''
          Either ''${my.www.coffeepaste.domain} or
          ''${my.www.coffeepaste.virtualHost} must be non-null.
        '';
      }

      {
        assertion = (cfg.domain == null) || (cfg.virtualHost == null);
        message = ''
          Both ''${my.www.coffeepaste.domain} and
          ''${my.www.coffeepaste.domain} cannot be
          non-null at the same time.
        '';
      }
    ];

    security.acme.certs = optionalAttrs (cfg.domain != null) (
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
      }
    );

    services = let
      domain =
        if cfg.domain != null
        then cfg.domain
        else "${cfg.virtualHost}/${cfg.location}/";
    in {
      coffeepaste = {
        enable = true;
        url = "https://${domain}";
      };

      nginx = let
        vhost =
          if cfg.domain != null
          then cfg.domain
          else cfg.virtualHost;

        proxy = {
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

        putRequest = {
          proxyPass = "http://coffeepaste";
          extraConfig = ''
            limit_req zone=put_request_by_addr burst=10;
            proxy_pass_request_headers on;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };

        errorPage = ''
          error_page ${builtins.toString cfg.putRequestCode} = @putrequest;
        '';
      in {
        enable = true;

        upstreams = {
          coffeepaste = {
            servers."localhost:${builtins.toString config.services.coffeepaste.listenPort}" = {};
            extraConfig = ''
              zone coffeepaste 64k;
              keepalive 8;
            '';
          };
        };

        virtualHosts.${vhost} =
          if cfg.domain != null
          then {
            serverName = "${cfg.domain} www.${cfg.domain}";
            kTLS = true;
            forceSSL = true;
            useACMEHost = acmeHost;
            extraConfig = ''
              ${errorPage}
              include /etc/nginx/bots.d/blockbots.conf;
              include /etc/nginx/bots.d/ddos.conf;
            '';

            locations = {
              "/" = proxy;
              "@putrequest" = putRequest;
            };
          }
          else {
            extraConfig = ''
              ${errorPage}
            '';
            locations = {
              "/${cfg.location}/" = proxy;
              "@putrequest" = putRequest;
            };
          };
      };
    };
  };
}
