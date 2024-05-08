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
        #!${prev.bash}/bin/bash
        shopt -s globstar
        export VAULT_NAMESPACE="admin"
        export PATH="${prev.vault}/bin:${prev.sops}/bin:$PATH"
        VAULT="${prev.vault}/bin/vault"

        pushd "${config.home.homeDirectory}/src/cfg" &>/dev/null || exit 1
        sops exec-file --output-type json ./host/secrets.yaml "\"$VAULT\" kv put -mount=secret secrets @{}"
        sops exec-file --output-type json ./home/secrets.yaml "\"$VAULT\" kv put -mount=secret user-secrets @{}"
        popd &>/dev/null || exit
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
