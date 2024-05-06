{
  lib,
  config,
  pkgs,
  ...
}: {
  xdg = {
    enable = true;

    # Setup XDG_* variables
    configHome = "${config.home.homeDirectory}/.config";
    dataHome = "${config.home.homeDirectory}/.local/share";
    cacheHome = "${config.home.homeDirectory}/.cache";
    stateHome = "${config.home.homeDirectory}/.local/state";

    userDirs = {
      enable = lib.strings.hasSuffix "-linux" pkgs.system;

      desktop = null;
      documents = lib.mkDefault "${config.home.homeDirectory}/doc";
      music = lib.mkDefault "${config.home.homeDirectory}/media/music";
      pictures = lib.mkDefault "${config.home.homeDirectory}/media/img";
      publicShare = lib.mkDefault "${config.home.homeDirectory}/media/sync";
      videos = lib.mkDefault "${config.home.homeDirectory}/media/video";
    };

    # Setup xdg default programs
    mime.enable = lib.strings.hasSuffix "-linux" pkgs.system;
    mimeApps.enable = lib.strings.hasSuffix "-linux" pkgs.system;
  };
}
