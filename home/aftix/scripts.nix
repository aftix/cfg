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
        #! nix-shell -p bash tofi pass wl-clipboard
        #! nix-shell -I nixpkgs=${nixpkgs}

        shopt -s nullglob globstar

        export GNUPGHOME="${config.home.homeDirectory}/.local/share/gnupg" PASSWORD_STORE_DIR="${config.home.homeDirectory}/.local/share/password-store"
        prefix="${config.home.homeDirectory}/.local/share/password-store"
        password_files=( "$prefix"/**/*.gpg )
        password_files=( "''${password_files[@]#"$prefix"/}" )
        password_files=( "''${password_files[@]%.gpg}" )

        password=$(printf '%s\n' "''${password_files[@]}" | tofi --prompt-text "Password" "$@")

        [[ -n $password ]] || exit

        PINENTRY_USER_DATA=qt pass show -c "$password" 2>&1
      '';
    };

    "bin/syncvault" = {
      executable = true;
      text = ''
        #!/usr/bin/env NIXPKGS_ALLOW_UNFREE=1 nix-shell
        #! nix-shell -i bash --pure --keep NIXPKGS_ALLOW_UNFREE --keep VAULT_ADDR --keep VAULT_TOKEN
        #! nix-shell -p bash gnused gnugrep gnupg vault
        #! nix-shell -I nixpkgs=${nixpkgs}

        shopt -s globstar
        export VAULT_NAMESPACE="admin"
        export GNUPGHOME="${config.home.homeDirectory}/.local/share/gnupg"

        cd "${config.home.homeDirectory}/.local/share/password-store" || exit

        for line in **/*; do
          grep -q '\.git' <<< "$line" && continue
          name="$(echo "$line" | sed 's/\.gpg$//')"
          data="$(gpg --decrypt "$line" 2>/dev/null | sed 's/^@/\\@/')"
          vault kv put "secret/password-store/$name" "data=$data"
        done
      '';
    };
  };
}
