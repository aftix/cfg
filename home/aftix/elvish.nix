{ config, ... }:

{
  # Too complicated for home manager, just sync with _external configuration
  xdg.configFile."elvish".source = ./_external.elvish;

  # This changes often, just symlink it to the repo
  # Currently config.lib.file.mkOutOfStoreSymlink doesn't work on unstable, activation script workaround
  home.activation = {
    updateBookmarks = ''
      export ROOT="${config.home.homeDirectory}/src/cfg/home/aftix"
      ln -sf "$ROOT/_external/bookmarks" .config/bookmarks
    '';
  };
}
