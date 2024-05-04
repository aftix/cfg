{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault mkIf;
  inherit (config.xdg) dataHome;
in {
  nixpkgs.overlays = [
    (final: prev: {
      pinentry-custom = pkgs.writeScriptBin "pinentry-custom" ''
        #!${pkgs.stdenv.shell}
        if [ -z "$PINENTRY_USER_DATA" ] ; then
          exec pinentry-curses "$@"
          exit 0
        fi

        case $PINENTRY_USER_DATA in
        qt)
          exec ${pkgs.pinentry-qt}/bin/pinentry-qt "$@"
          ;;
        none)
          exit 1
          ;;
        *)
          exec ${pkgs.pinentry-qt}/bin/pinentry-curses "$@"
        esac
      '';
    })
  ];

  home.packages = with pkgs;
    mkIf (system == "x86_64-linux") [
      pinentry-qt
      pinentry-custom
    ];

  programs.gpg = {
    enable = true;
    homedir = mkDefault "${dataHome}/gnupg";

    settings = {
      keyserver = "keys.gnupg.net";
    };
  };

  services.gpg-agent = {
    enable = pkgs.system == "x86_64-linux";
    extraConfig = mkDefault ''
      pinentry-program ${pkgs.pinentry-custom}/bin/pinentry-custom
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
        ExecStart = "${pkgs.gnupg}/bin/gpg --refresh-keys";
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
}
