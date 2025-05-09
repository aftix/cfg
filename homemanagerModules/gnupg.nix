# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault mkIf;
  inherit (config.xdg) dataHome;

  pinentry-custom = pkgs.writeShellApplication {
    name = "pinentry-custom";
    runtimeInputs = with pkgs; [pinentry-qt];
    text = ''
      if [ -z "''${PINENTRY_USER_DATA-}" ] ; then
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
in {
  home.packages = with pkgs;
    mkIf (lib.strings.hasSuffix "-linux" pkgs.system) [
      pinentry-qt
      pinentry-custom
    ];

  programs.gpg = {
    enable = true;
    homedir = mkDefault "${dataHome}/gnupg";

    settings = {
      keyserver = "keys.gnupg.net";
    };
    scdaemonSettings = {
      disable-ccid = true;
    };
  };

  services.gpg-agent = rec {
    enable = lib.strings.hasSuffix "-linux" pkgs.system;
    enableSshSupport = enable;
    extraConfig = mkDefault ''
      pinentry-program ${lib.getExe pinentry-custom}
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
        ExecStart = "${lib.getExe pkgs.gnupg} --refresh-keys";
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
