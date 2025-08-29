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
}
