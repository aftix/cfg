{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.lists) optional;
  wwwCfg = config.my.www;
  cfg = config.my.www.blog;

  acmeHost =
    if cfg.acmeDomain == null
    then cfg.domain
    else cfg.acmeDomain;
in {
  options.my.www.blog = {
    enable = mkEnableOption "blog";

    domain = mkOption {
      type = lib.types.str;
    };

    acmeDomain = mkOption {
      default = wwwCfg.acmeDomain;
      type = with lib.types; nullOr str;
      description = "null to use \${config.my.www.blog.domain}";
    };

    adventofcode = mkEnableOption "adventofcode";
    aftgraphs = mkEnableOption "aftgraphs";
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules =
      [
        "d ${wwwCfg.root}/${cfg.domain} 0775 ${wwwCfg.user} ${wwwCfg.group} -"
        "Z ${wwwCfg.root}/${cfg.domain} 0775 ${wwwCfg.user} ${wwwCfg.group} -"
      ]
      ++ optional cfg.adventofcode "d ${wwwCfg.root}/advent2023 0775 ${wwwCfg.user} ${wwwCfg.group} -"
      ++ optional cfg.aftgraphs "d ${wwwCfg.root}/simulations 0775 ${wwwCfg.user} ${wwwCfg.group} -";

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

    services.nginx = {
      enable = true;

      virtualHosts.${cfg.domain} = {
        root = "${wwwCfg.root}/${cfg.domain}";
        serverName = "${cfg.domain} www.${cfg.domain}";
        kTLS = true;
        forceSSL = true;
        useACMEHost = cfg.domain;
        extraConfig = ''
          include /etc/nginx/bots.d/blockbots.conf;
          include /etc/nginx/bots.d/ddos.conf;
        '';

        locations = {
          "/".tryFiles = "$uri $uri/ =404";

          "/advent2023/" = mkIf cfg.adventofcode {
            alias = "${wwwCfg.root}/advent2023/";
            extraConfig = ''
              fancyindex on;
              fancyindex_exact_size off;
              fancyindex_localtime on;
            '';
          };

          "/aftgraphs/" = mkIf cfg.aftgraphs {
            alias = "${wwwCfg.root}/simulations/";
            extraConfig = ''
              fancyindex on;
              fancyindex_exact_size off;
              fancyindex_localtime on;
              add_header "Cross-Origin-Opener-Policy" "same-origin";
              add_header "Cross-Origin-Embedder-Policy" "require-corp";
            '';
          };
        };
      };
    };
  };
}
