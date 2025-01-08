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
    ./forgejo.nix
    ./grocy.nix
    ./kanidm.nix
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

    acmeDomain = mkOption {
      default = null;
      type = with lib.types; nullOr str;
      description = ''
        If non-null, will set the acmeDomain option
        values for every www service.
      '';
    };

    root = mkOption {
      default = "/srv";
      type = lib.types.str;
      description = ''
        Home directory of the ''${my.www.user} user.
        www services that are not proxy passes (to e.g. phpfpm)
        should serve files from subdirectories of this root directory.
      '';
    };

    ip = mkOption {
      default = "";
      type = lib.types.str;
    };
    ipv6 = mkOption {
      default = "";
      type = lib.types.str;
    };

    user = mkOption {
      default = "www";
      type = lib.types.str;
      description = "User to run nginx as";
    };

    group = mkOption {
      default = "www";
      type = lib.types.str;
      description = "Group to run nginx as";
    };

    keys = mkOption {
      default = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMmFgG1EuQDoJb8pQcxnhjqbncrpJGZ3iNon/gu0bXiE aftix@aftix.xyz"
      ];
      type = with lib.types; listOf str;
      description = "List of public ssh keys for remote login as \${my.www.user}";
    };

    streamConfig = mkOption {
      default = [];
      type = with lib.types; listOf str;
    };

    nginxBlockerPatches = mkOption {
      default = [];
      type = with lib.types; listOf path;
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

    systemd.tmpfiles.settings."10-nginx-conf" = let
      blockerPkg = pkgs.nginx_blocker.overrideAttrs {patches = cfg.nginxBlockerPatches;};
    in {
      ${cfg.root} = rec {
        d = {
          mode = "0755";
          inherit (cfg) user group;
        };
        Z = d;
      };

      "/etc/nginx/conf.d"."L+".argument = "${blockerPkg}/conf.d";
      "/etc/nginx/bots.d"."L+".argument = "${blockerPkg}/bots.d";
    };

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
    };
  };
}
