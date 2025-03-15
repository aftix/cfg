{lib, ...}: {
  imports = [
    ../home/opt/sops.nix

    ../home/opt/development.nix
    ../home/opt/helix.nix
    ../home/opt/neoutils.nix

    ../home/opt/firefox.nix

    ../home/opt/dunst.nix
    ../home/opt/hypr.nix
    ../home/opt/kitty.nix
    ../home/opt/media.nix
    ../home/opt/stylix.nix
  ];

  xdg.userDirs.createDirectories = lib.mkForce false;

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
