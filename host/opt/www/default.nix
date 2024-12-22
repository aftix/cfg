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
    ./attic.nix
    ./barcodebuddy.nix
    ./blog.nix
    ./coffeepaste.nix
    ./grocy.nix
    ./matrix.nix
    ./rss.nix
    ./searx.nix
    ./znc.nix
  ];

  options.my.www = {
    hostname = mkOption {
      default = "aftix.xyz";
      type = lib.types.str;
    };

    ip = mkOption {
      default = "";
      type = lib.types.str;
    };
    ipv6 = mkOption {
      default = "";
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

    keys = mkOption {
      default = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMmFgG1EuQDoJb8pQcxnhjqbncrpJGZ3iNon/gu0bXiE aftix@aftix.xyz"
      ];
    };

    streamConfig = mkOption {
      default = [];
      type = lib.types.listOf lib.types.str;
    };

    putRequestCode = mkOption {
      default = 599;
      type = lib.types.ints.positive;
    };

    nginxBlockerPatches = mkOption {
      default = [];
      type = lib.types.listOf lib.types.path;
    };
  };

  config = {
    sops.secrets = {
      porkbun_api_key = {
        inherit (cfg) group;
        owner = cfg.user;
      };
      porkbun_secret_api_key = {
        inherit (cfg) group;
        owner = cfg.user;
      };
    };

    users = {
      users.${cfg.user} = {
        inherit (cfg) group;
        password = "";
        shell = pkgs.bash;
        isSystemUser = true;
        home = lib.mkOverride 990 cfg.root;
        openssh.authorizedKeys.keys = cfg.keys;
      };

      groups.${cfg.group} = {};
    };

    networking.firewall = {
      allowedTCPPorts = [80 443];
      allowedUDPPorts = [80 443];
    };

    services = {
      nginx = {
        inherit (cfg) user group;
        enable = true;
        enableReload = true;

        additionalModules = with pkgs.nginxModules; [fancyindex];

        appendHttpConfig = ''
          limit_req_zone $binary_remote_addr zone=put_request_by_addr:20m rate=100r/s;
          include /etc/nginx/conf.d/globalblacklist.conf;
          include /etc/nginx/conf.d/botblocker-nginx-settings.conf;
        '';

        streamConfig = lib.strings.concatLines cfg.streamConfig;
      };

      openssh.settings.AllowUsers = [cfg.user];
    };

    systemd.tmpfiles.rules = let
      blockerPkg = pkgs.nginx_blocker.overrideAttrs {patches = cfg.nginxBlockerPatches;};
    in [
      "d ${cfg.root} 0775 ${cfg.user} ${cfg.group} -"
      "Z ${cfg.root} 0775 ${cfg.user} ${cfg.group} -"
      "L+ /etc/nginx/conf.d - - - - ${blockerPkg}/conf.d"
      "L+ /etc/nginx/bots.d - - - - ${blockerPkg}/bots.d"
    ];

    security.acme = {
      acceptTerms = true;

      defaults = {
        email = "aftix@aftix.xyz";
        dnsProvider = "porkbun";
        inherit (cfg) group;
        credentialFiles = {
          PORKBUN_SECRET_API_KEY_FILE = config.sops.secrets.porkbun_secret_api_key.path;
          PORKBUN_API_KEY_FILE = config.sops.secrets.porkbun_api_key.path;
        };
      };

      certs.${cfg.hostname} = {
        inherit (cfg) group;
        extraDomainNames = ["www.${cfg.hostname}"];
      };
    };
  };
}
