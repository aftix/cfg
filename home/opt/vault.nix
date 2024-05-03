{
  upkgs,
  config,
  nixpkgs,
  lib,
  ...
}: let
  inherit (lib) mkDefault;
in {
  home = {
    packages = [upkgs.vault];
    sessionVariables = {
      VAULT_ADDR = mkDefault "https://vault.aftix.com";
      VAULT_NAMESPACE = mkDefault "admin";
    };
  };

  xdg.configFile = {
    "bin/syncvault" = {
      executable = true;
      text = ''
        #!/usr/bin/env nix-shell
        #! nix-shell -i bash --pure --keep VAULT_ADDR --keep VAULT_TOKEN
        #! nix-shell -p bash gnused gnugrep sops
        #! nix-shell -I nixpkgs=${nixpkgs}

        shopt -s globstar
        export VAULT_NAMESPACE="admin"
        VAULT="${upkgs.vault}/bin/vault"

        cd "${config.home.homeDirectory}/src/cfg" || exit
        sops exec-file --output-type json secrets.yaml "\"$VAULT\" kv put -mount=secret secrets @{}"
        sops exec-file --output-type json ./home/aftix/secrets.yaml "\"$VAULT\" kv put -mount=secret user-secrets @{}"
      '';
    };
  };
}
