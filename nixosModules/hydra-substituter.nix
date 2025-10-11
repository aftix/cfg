# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  config,
  lib,
  ...
}: let
  inherit (lib) mkOption types;
  cfg = config.aftix.hydra-substituter;
in {
  options.aftix.hydra-substituter = {
    enable = lib.mkEnableOption "custom hydra substituter";

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
      default = null;
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
        s3://${config.sops.placeholder.${cfg.bucket-secret}}?${compression}&write-nar-listing=0&${secretKey}&scheme=https&endpoint=${config.sops.placeholder.${cfg.store-url-secret}}
      '';

      type = types.uniq types.str;
      readOnly = true;
      description = "Store URI for use in sops templates";
    };

    extra-credentialed-services = mkOption {
      default = [];
      description = ''
        Additional systemd services that need the hydra substituter credentials.
        This will only be services that invoke nix in a way that
          1) requires substituters
          2) does not use the nix-daemon
      '';
      type = types.listOf types.str;
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && cfg.credentials-file-path != null) {
      systemd.services = let
        mkServiceConfig = name: {${name}.serviceConfig.EnvironmentFile = cfg.credentials-file-path;};
        serviceConfigs = lib.map mkServiceConfig (["nix-daemon"] ++ cfg.extra-credentialed-services);
      in
        lib.mkMerge serviceConfigs;
    })

    (lib.mkIf cfg.enable {
      nix.extraOptions = ''
        !include ${config.sops.templates.hydraSubstituter.path}
        ${lib.optionalString (cfg.public-key-secret != null) "!include ${config.sops.templates.hydraPublicKey.path}"}
      '';
    })

    {
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
    }
  ];
}
