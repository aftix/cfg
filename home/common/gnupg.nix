{
  config,
  lib,
  upkgs,
  nixpkgs,
  ...
}: {
  programs.gpg = {
    enable = true;
    homedir = lib.mkDefault "${config.home.homeDirectory}/.local/share/gnupg";

    settings = {
      keyserver = "keys.gnupg.net";
    };
  };

  services.gpg-agent = {
    enable = upkgs.system == "x86_64-linux";
    extraConfig = lib.mkDefault ''
      pinentry-program ${config.home.homeDirectory}/.config/bin/pinentry-custom
    '';
  };

  systemd.user = {
    services.keyrefresh = {
      Unit = {
        Description = "Refresh gpg keys";
        Requires = ["network.target"];
      };
      Service = {
        Type = "oneshot";
        Environment = ''GNUPGHOME="${config.programs.gpg.homedir}"'';
        ExecStart = "${upkgs.gnupg}/bin/gpg --refresh-keys";
      };
    };

    timers.keyrefresh = {
      Unit.Description = "Refresh gpg keys every 8 hours";
      Timer = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = 600;
      };
      Install.WantedBy = ["timers.target"];
    };
  };

  xdg.configFile."bin/pinetry-custom" = lib.mkIf (upkgs.system == "x86_64-linux") {
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
}
