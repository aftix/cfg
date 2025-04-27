# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault;
  inherit (lib.strings) hasSuffix;
  inherit (config.home) homeDirectory;
in {
  xdg = {
    enable = true;

    # Setup XDG_* variables
    configHome = homeDirectory + "/.config";
    dataHome = homeDirectory + "/.local/share";
    cacheHome = homeDirectory + "/.cache";
    stateHome = homeDirectory + "/.local/state";

    userDirs = {
      enable = hasSuffix "-linux" pkgs.system;
      createDirectories = mkDefault true;

      desktop = mkDefault null;
      templates = mkDefault null;

      documents = mkDefault "${homeDirectory}/doc";
      music = mkDefault "${homeDirectory}/media/music";
      pictures = mkDefault "${homeDirectory}/media/img";
      publicShare = mkDefault "${homeDirectory}/media/sync";
      videos = mkDefault "${homeDirectory}/media/video";
    };

    # Setup xdg default programs
    mime.enable = hasSuffix "-linux" pkgs.system;
    mimeApps.enable = hasSuffix "-linux" pkgs.system;
  };

  aftix.shell.neededDirs = with config.xdg; [
    configHome
    dataHome
    cacheHome
    stateHome
  ];
}
