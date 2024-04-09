{
  upkgs,
  config,
  ...
}: {
  xdg.configFile = {
    "bin/pinentry-custom" = {
      executable = true;
      text = ''
        #!"${upkgs.bash}/bin/bash"

        if [ -z "$PINENTRY_USER_DATA" ] ; then
          exec "${upkgs.pinentry-gtk2}/bin/pinentry-curses" "$@"
          exit 0
        fi

        case $PINENTRY_USER_DATA in
        gtk)
          exec "${upkgs.pinentry-gtk2}/bin/pinentry-gtk-2" "$@"
          ;;
        none)
          exit 1
          ;;
        *)
          exec "${upkgs.pinentry-gtk2}/bin/pinentry-curses" "$@"
        esac
      '';
    };

    "bin/passmenu" = {
      executable = true;
      text = ''
        #!"${upkgs.bash}/bin/bash"

        shopt -s nullglob globstar

        export GNUPGHOME="${config.home.homeDirectory}/.local/share/gnupg" PASSWORD_STORE_DIR="${config.home.homeDirectory}/.local/share/password-store"
        prefix="${config.home.homeDirectory}/.local/share/password-store"
        password_files=( "$prefix"/**/*.gpg )
        password_files=( "''${password_files[@]#"$prefix"/}" )
        password_files=( "''${password_files[@]%.gpg}" )

        password=$(printf '%s\n' "''${password_files[@]}" | tofi --prompt-text "Password" "$@")

        [[ -n $password ]] || exit

        PINENTRY_USER_DATA=gtk pass show -c "$password" 2>&1
      '';
    };

    "bin/screenshot.sh" = {
      executable = true;
      text = ''
        #!"${upkgs.bash}/bin/bash"

        TOFI="${upkgs.tofi}/bin/tofi"
        name="$1" remove="yes"
        if [ "''${name:=default}" = "default" ] ; then
            name="$(mktemp /tmp/shotXXXXXXXXX.png)"
            rm -f "$name"
        elif [ "$name" = "ask" ] ; then
          name="$(printf "" | "$TOFI" -p "Screenshot name")"
          remove="no"
        fi
        [[ "$name" =~ \.png$ ]] || name="''${name%.*}.png"

        "${upkgs.grim}/bin/grim" -g "$(${upkgs.slurp}/bin/slurp)" "$name"

        if [ "$2" = "copy" ]; then
          source <("${upkgs.systemd}/bin/systemctl" --user show-environment)
          url="$("${upkgs.curl}/bin/curl" --upload-file "$name" https://file.aftix.xyz)"
          "$TOFI" -p "URL: $url"
          "${upkgs.coreutils}/bin/echo" -n "$url" | "${upkgs.wl-clipboard}/bin/wl-copy"
        else
          "${upkgs.wl-clipboard}/bin/wl-copy" -t image/png < "$name"
        fi

        [ "$remove" = yes ] && rm -f "$name"
      '';
    };

    "bin/syncvault" = {
      executable = true;
      text = ''
        #!"${upkgs.bash}/bin/bash"
        shopt -s globstar
        export VAULT_NAMESPACE="admin"
        SED="${upkgs.gnused}/bin/sed"

        cd "${config.home.homeDirectory}/.local/share/password-store" || exit

        for line in "**/*"; do
          "${upkgs.coreutils}/bin/grep" -q '\.git' <<< "$line" && continue
          name="$("${upkgs.coreutils}/bin/echo" "$line" | "$SED" 's/\.gpg$//')"
          data="$(gpg --decrypt "$line" 2>/dev/null | "$SED" 's/^@/\\@/')"
          "${upkgs.vault}" kv put "secret/password-store/$name" "data=$data"
        done
      '';
    };
  };
}
