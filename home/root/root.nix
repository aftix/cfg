{home-impermanence, ...}: {
  imports = [
    home-impermanence
    ../aftix/helix.nix
  ];

  home = {
    username = "root";
    homeDirectory = "/root";
    stateVersion = "23.11"; # DO NOT CHANGE
  };

  programs.starship.settings = {
    "$schema" = "https://starship.rs/config-schema.json";
    add_newline = true;
    package.disabled = true;
  };

  programs.home-manager.enable = true;
}
