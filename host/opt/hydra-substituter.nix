{
  config,
  lib,
  ...
}: let
  inherit (lib) mkOption types;
  cfg = config.aftix.hydra-substituter;
in {
  options.aftix.hydra-substituter = {
    bucket-secret = mkOption {
      default = "hydra_store_bucket";
      type = types.uniq types.str;
    };

    store-url-secret = mkOption {
      default = "hydra_store_url";
      type = types.uniq types.str;
    };

    credentials-file-path = mkOption {
      default = config.sops.templates.hydraStore.path;
      type = types.uniq (types.nullOr types.path);
    };

    secret-file-path = mkOption {
      default = config.sops.secrets.hydra_store_secret_key.path;
      type = types.uniq (types.nullOr types.path);
    };

    public-key-secret = mkOption {
      default = "hydra_store_public_key";
      type = types.uniq (types.nullOr types.str);
    };

    store-uri = mkOption {
      default = let
        compression = "compression=zstd&parallel-compression=true&log-compression=br&ls-compression=br";
        secretKey = lib.optionalString (cfg.secret-file-path != null) "secret-key=${cfg.secret-file-path}";
      in ''
        s3://${config.sops.placeholder.${cfg.bucket-secret}}?${compression}&write-nar-listing=1&${secretKey}&scheme=https&endpoint=${config.sops.placeholder.${cfg.store-url-secret}}
      '';

      type = types.uniq types.str;
      readOnly = true;
      description = "Store URI for use in sops templates";
    };
  };

  config = {
    sops.templates = {
      hydraSubstituter = {
        mode = "0444";
        content = ''
          extra-substituters = ${cfg.store-uri}
        '';
      };

      hydraPublicKey = lib.mkIf (cfg.public-key-secret != null) {
        mode = "0444";
        content = ''
          extra-trusted-public-keys = ${config.sops.placeholder.${cfg.public-key-secret}}
        '';
      };
    };

    systemd.services.nix-daemon.serviceConfig.EnvironmentFile = lib.mkIf (cfg.credentials-file-path != null) cfg.credentials-file-path;

    nix.extraOptions = ''
      !include ${config.sops.templates.hydraSubstituter.path}
      ${lib.optionalString (cfg.public-key-secret != null) "!include ${config.sops.templates.hydraPublicKey.path}"}
    '';
  };
}
