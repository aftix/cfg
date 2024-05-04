{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkDefault;
in {
  nixpkgs.overlays = [
    (final: prev: {
      syncvault = pkgs.writeScriptBin "syncvault" ''
        #!${pkgs.stdenv.shell}
        shopt -s globstar
        export VAULT_NAMESPACE="admin"
        export PATH="${pkgs.vault}/bin:${pkgs.sops}/bin:$PATH"
        VAULT="${pkgs.vault}/bin/vault"

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
