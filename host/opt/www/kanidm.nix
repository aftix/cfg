{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.options) mkOption mkEnableOption;

  cfg = config.my.www;
  fullHostname = "${cfg.kanidm.subdomain}.${cfg.hostname}";
in {
  options.my.www.kanidm = {
    enable = mkEnableOption "kanidm";

    subdomain = mkOption {
      default = "identity";
      type = lib.types.str;
    };

    port = mkOption {
      default = 8998;
      type = lib.types.ints.positive;
    };
  };

  config = lib.mkIf cfg.kanidm.enable {
    security.acme.certs.${cfg.hostname}.extraDomainNames = [
      "${fullHostname}"
      "www.${fullHostname}"
    ];

    services = {
      kanidm = {
        clientSettings.uri = "https://${fullHostname}";
        enableClient = true;
        enableServer = true;
        package = pkgs.kanidm_1_4.override {enableSecretProvisioning = true;};
        provision = {
          enable = true;
          adminPasswordFile = config.sops.secrets.kanidm_admin_password.path;
          idmAdminPasswordFile = config.sops.secrets.kanidm_idmadmin_password.path;
          instanceUrl = "https://localhost:${builtins.toString cfg.kanidm.port}";
        };
        serverSettings = {
          bindaddress = "127.0.0.1:${builtins.toString cfg.kanidm.port}";
          domain = fullHostname;
          online_backup.versions = 7;
          origin = "https://${fullHostname}";
          tls_key = "/var/lib/acme/${cfg.hostname}/key.pem";
          tls_chain = "/var/lib/acme/${cfg.hostname}/fullchain.pem";
          trust_x_forward_for = true;
        };
      };

      nginx.virtualHosts.${fullHostname} = {
        serverName = "${fullHostname} www.${fullHostname}";
        kTLS = true;
        forceSSL = true;
        useACMEHost = cfg.hostname;
        extraConfig = ''
          include /etc/nginx/bots.d/blockbots.conf;
          include /etc/nginx/bots.d/ddos.conf;
        '';

        locations."/" = {
          proxyPass = "https://localhost:${builtins.toString cfg.kanidm.port}";
          extraConfig = ''
            proxy_http_version 1.1;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };
    };

    sops.secrets = {
      kanidm_admin_password = {
        owner = "kanidm";
        group = "kanidm";
      };
      kanidm_idmadmin_password = {
        owner = "kanidm";
        group = "kanidm";
      };
    };

    users.users.kanidm = {
      extraGroups = [cfg.group];
      shell = lib.getExe' pkgs.util-linux "nologin";
    };
  };
}
