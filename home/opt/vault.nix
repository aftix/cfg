{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkDefault;
in {
  nixpkgs.overlays = [
    (_: prev: {
      syncvault = prev.writeScriptBin "syncvault" ''
        #!${prev.stdenv.shell}
        shopt -s globstar
        export VAULT_NAMESPACE="admin"
        export PATH="${prev.vault}/bin:${prev.sops}/bin:$PATH"
        VAULT="${prev.vault}/bin/vault"

        cd "${config.home.homeDirectory}/src/cfg" || exit
        sops exec-file --output-type json secrets.yaml "\"$VAULT\" kv put -mount=secret secrets @{}"
        sops exec-file --output-type json ./home/aftix/secrets.yaml "\"$VAULT\" kv put -mount=secret user-secrets @{}"
      '';
    })
  ];

  home = {
    packages = with pkgs; [vault syncvault];
    sessionVariables = {
      VAULT_ADDR = mkDefault "https://vault.aftix.xyz";
      VAULT_NAMESPACE = mkDefault "admin";
    };
  };
}
