_: {
  imports = [
    ./common

    ./opt/sops.nix

    ./opt/development.nix
    ./opt/helix.nix
    ./opt/neoutils.nix

    ./opt/firefox.nix

    ./opt/dunst.nix
    ./opt/hypr.nix
    ./opt/kitty.nix
    ./opt/media.nix
    ./opt/stylix.nix
  ];

  my = {
    shell.elvish.enable = true;

    docs = {
      enable = true;
      prefix = "aftix-iso";
    };

    development = {
      rust = false;
      go = false;
      typescript = false;
      gh = false;
    };
  };

  home = {
    username = "nixos";
    homeDirectory = "/home/nixos";
    stateVersion = "23.11"; # DO NOT CHANGE
  };
}
