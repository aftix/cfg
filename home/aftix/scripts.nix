{
  upkgs,
  config,
  ...
}: {
  xdg.configFile = {
    "bin/pinentry-custom" = {
      executable = true;
      text = ''
        #!${upkgs.bash}/bin/bash

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
        #!${upkgs.bash}/bin/bash

        shopt -s nullglob globstar

        export GNUPGHOME="${config.home.homeDirectory}/.local/share/password-store"
        prefix="${config.home.homeDirectory}/.local/share/password-store"
        password_files=( "$prefix"/**/*.gpg )
        password_files=( "$${password_files[@]#"$prefix"/}" )
        password_files=( "$${password_files[@]%.gpg}" )

        password=$(printf '%s\n' "$${password_files[@]}" | tofi --prompt-text "Password" "$@")

        [[ -n $password ]] || exit

        PINENTRY_USER_DATA=gtk pass show -c "$password" 2>&1
      '';
    };
  };
}
