{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (lib.lists) optional;
  cfg = config.my.www;
in {
  options.my.www = {
    adventofcode = mkEnableOption "adventofcode";
    aftgraphs = mkEnableOption "aftgraphs";
    blog = mkEnableOption "blog";
  };

  config = mkIf cfg.blog {
    systemd.tmpfiles.rules =
      [
        "d ${cfg.root}/${cfg.hostname} 0775 ${cfg.user} ${cfg.group} -"
        "Z ${cfg.root}/${cfg.hostname} 0775 ${cfg.user} ${cfg.group} -"
      ]
      ++ optional cfg.adventofcode "d ${cfg.root}/advent2023 0775 ${cfg.user} ${cfg.group} -"
      ++ optional cfg.aftgraphs "d ${cfg.root}/simulations 0775 ${cfg.user} ${cfg.group} -";

    services.nginx.virtualHosts.${cfg.hostname} = {
      root = "${cfg.root}/${cfg.hostname}";
      serverName = "${cfg.hostname} www.${cfg.hostname}";
      kTLS = true;
      forceSSL = true;
      useACMEHost = cfg.hostname;
      extraConfig = ''
        error_page ${builtins.toString cfg.putRequestCode} = @putrequest;
        include /etc/nginx/bots.d/blockbots.conf;
        include /etc/nginx/bots.d/ddos.conf;
      '';

      locations = {
        "/".tryFiles = "$uri $uri/ =404";

        "/searx/".return = mkIf cfg.searx.enable "https://${cfg.searx.subdomain}.${cfg.hostname}/?$args";

        "/advent2023/" = mkIf cfg.adventofcode {
          alias = "${cfg.root}/advent2023/";
          extraConfig = ''
            fancyindex on;
            fancyindex_exact_size off;
            fancyindex_localtime on;
          '';
        };

        "/aftgraphs/" = mkIf cfg.aftgraphs {
          alias = "${cfg.root}/simulations/";
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
}
