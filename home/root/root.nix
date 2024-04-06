{ home-impermanence, upkgs, spkgs, ... }:

{
  imports = [
    home-impermanence
    ../aftix/helix.nix
  ];

  home.username = "root";
  home.homeDirectory = "/root";

  programs.starship.settings = {
    "$schema" = "https://starship.rs/config-schema.json";
    add_newline = true;
    package.disabled = true;
  };

  home.stateVersion = "23.11";
  programs.home-manager.enable = true;
}
