# This module defines things that should be the same across all machines/configs
{
  lib,
  config,
  ...
}: let
  inherit (lib) mkOption types;
  inherit (config.aftix) statics;
in {
  options.aftix.statics = {
    primaryDomain = mkOption {
      default = "aftix.xyz";
      type = types.str;
      readOnly = true;
      description = "My primary domain name";
    };

    identityService = mkOption {
      default = "identity.${statics.primaryDomain}";
      type = types.str;
      readOnly = true;
      description = "Domain of centralized identity service";
    };

    ldapServer = mkOption {
      default = statics.identityService;
      type = types.str;
      readOnly = true;
      description = "Domain of LDAP server for centralized identity service";
    };

    consulService = mkOption {
      default = "consul.${statics.primaryDomain}";
      type = types.str;
      readOnly = true;
      description = "Domain of consul for service discovery and meshing";
    };

    vaultServer = mkOption {
      default = "vault.${statics.primaryDomain}";
      type = types.str;
      readOnly = true;
      description = "Domain of HC Vault instance for centralized secrets management";
    };
  };
}
