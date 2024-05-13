{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.options) mkOption;
  cfg = config.my.www;
in {
  imports = [
    ./blog.nix
    ./searx.nix
    ./znc.nix
  ];

  options.my.www = {
    hostname = mkOption {
      default = "aftix.xyz";
      type = lib.types.str;
    };

    root = mkOption {
      default = "/srv";
      type = lib.types.str;
    };

    user = mkOption {
      default = "www";
      type = lib.types.str;
    };

    group = mkOption {
      default = "www";
      type = lib.types.str;
    };

    acme-location-block = mkOption {
      default = {
        "^~ /.well-known/acme-challenge".extraConfig = ''
          location ^~ /.well-known/acme-challenge/ {
            default_type "text/plain";
            root ${cfg.root}/acme;
          }
        '';
      };
      readOnly = true;
    };
  };

  config = {
    users = {
      users.${cfg.user} = {
        inherit (cfg) group;
        password = "";
        shell = "/run/current-system/sw/bin/nologin";
        isSystemUser = true;
      };

      groups.${cfg.group} = {};
    };

    networking.firewall = {
      allowedTCPPorts = [80 443];
      allowedUDPPorts = [80 443];
    };

    services.nginx = {
      inherit (cfg) user group;
      enable = true;
      enableReload = true;

      additionalModules = with pkgs.nginxModules; [fancyindex];

      appendHttpConfig = ''
        limit_req_zone $binary_remote_addr zone=put_request_by_addr:20m rate=100r/s;
      '';
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.root} 0775 ${cfg.user} ${cfg.group} -"
      "d ${cfg.root}/acme 0775 ${cfg.user} ${cfg.group} -"
    ];

    security.acme = {
      acceptTerms = true;
      defaults = {
        email = "aftix@aftix.xyz";
        webroot = cfg.root + "/acme";
      };

      certs.${cfg.hostname} = {
        inherit (cfg) group;
        extraDomainNames = ["www.${cfg.hostname}"];
      };
    };
  };
}
