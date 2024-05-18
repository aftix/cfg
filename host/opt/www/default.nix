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
    ./coffeepaste.nix
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
        home = cfg.root;
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
        '';
      };

      openssh.settings.AllowUsers = [cfg.user];
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.root} 0775 ${cfg.user} ${cfg.group} -"
    ];

    security.acme = {
      acceptTerms = true;

      defaults = {
        email = "aftix@aftix.xyz";
        dnsProvider = "porkbun";
        group = cfg.group;
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
