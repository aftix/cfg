{
  pkgs,
  config,
  lib,
  sops-nix,
  ...
}: let
  inherit (lib.strings) escapeShellArg;
  keyFile = config.home.homeDirectory + "/.local/persist/.config/sops/age/keys.txt";
in {
  nixpkgs.overlays = [
    (_: prev: {
      add-passwd = prev.writeScriptBin "add-passwd" ''
        #!${prev.bash}/bin/bash
        export PATH="${prev.jq}/bin:${prev.sops}/bin:$PATH"
        export SOPS_AGE_KEY_FILE=${escapeShellArg keyFile}

        echo "Inserting password for $1"
        [[ -n "$2" ]] && echo "Username is $2"

        if [[ -z "$1" ]]; then
          echo "Requires argument to set password name" 2>&1
          exit 1
        fi

        pushd ${escapeShellArg config.home.homeDirectory}/src/cfg &>/dev/null || exit 1

        value="$(sops exec-file --output-type json ./home/secrets.yaml "cat '{}' | jq -r '.\"$1\"' ")"
        if [[ "$value" != "null" ]]; then
          read -p "Warning: password '$1' exists. Overwrite? (y/N) " CHOICE
          if [[ "$CHOICE" != "y" && "$CHOICE" != "Y" ]]; then
            echo "Exiting."
            exit 0
          fi
        fi

        read -rsp "Type password: " PASS
        echo ""
        read -rsp "Retype password: " PASS_CHECK
        if [[ "$PASS" != "$PASS_CHECK" ]]; then
          echo "Error: passwords did not match, exiting" 2>&1
          exit 1
        fi

        if [[ -n "$2" ]]; then
          sops --set '["$1"] {"password": "$PASS", "username": "$2"}' ./home/secrets.yaml
        else
          sops --set '["$1"] "$PASS"' ./home/secrets.yaml
        fi

        popd &>/dev/null || exit
      '';
    })
  ];
  imports = [sops-nix];

  sops = {
    defaultSopsFile = ../secrets.yaml;

    age = {inherit keyFile;};
  };

  home.packages = [pkgs.add-passwd];
}
