{
  upkgs,
  config,
  nixpkgs,
  ...
}: {
  home.packages = with upkgs; [
    grim
    slurp
    satty
  ];

  xdg.configFile = {
    "bin/pinentry-custom" = {
      executable = true;
      text = ''
        #!/usr/bin/env nix-shell
        #! nix-shell -i bash --pure --keep PINENTRY_USER_DATA
        #! nix-shell -p bash pinentry-qt
        #! nix-shell -I nixpkgs=${nixpkgs}

        if [ -z "$PINENTRY_USER_DATA" ] ; then
          exec pinentry-curses "$@"
          exit 0
        fi

        case $PINENTRY_USER_DATA in
        qt)
          exec pinentry-qt "$@"
          ;;
        none)
          exit 1
          ;;
        *)
          exec pinentry-curses "$@"
        esac
      '';
    };

    "bin/screenshot" = {
      executable = true;
      text = ''
        #!/usr/bin/env ${upkgs.bash}/bin/bash

        source <("${upkgs.systemd}/bin/systemctl" --user show-environment)

        "${upkgs.grim}/bin/grim" -g "$("${upkgs.slurp}/bin/slurp" -o -r -c '#ff0000ff')" - | \
        "${upkgs.satty}/bin/satty" --filename - --fullscreen --output-filename ~/media/screenshots/satty-$(date '+%Y%m%d-%H:%M:%S').png \
        --early-exit --initial-tool crop --copy-command "${upkgs.wl-clipboard}/bin/wl-copy"
      '';
    };

    "bin/passmenu" = {
      executable = true;
      text = ''
        #!/usr/bin/env nix-shell
        #! nix-shell -i bash --pure
        #! nix-shell -p bash tofi sops wl-clipboard systemd jq gnused

        shopt -s globstar nullglob
        source <(systemctl --user show-environment)

        cd "$HOME/src/cfg" || exit

        password="$(sops exec-file --output-type json ./home/aftix/secrets.yaml \
          "cat '{}' | jq -r 'to_entries[] | select(.key != \"private_keys\") | .key'" |\
          tofi --prompt-text "Password")"
        [[ -n "$password" ]] || exit

        sops exec-file --output-type json ./home/aftix/secrets.yaml \
          "cat '{}' | jq -r '.\"$password\".password? // .\"$password\"'" |\
          tr -d '\n' | wl-copy --paste-once
      '';
    };

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
