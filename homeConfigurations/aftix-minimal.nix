{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../home/opt/sops.nix

    ../home/opt/development.nix
    ../home/opt/helix.nix
    ../home/opt/neoutils.nix
    ../home/opt/stylix.nix
  ];

  home = {
    username = "aftix";
    homeDirectory = "/home/aftix";
    packages = with pkgs; [attic-client kitty.terminfo];
    stateVersion = "23.11"; # DO NOT CHANGE
  };

  xdg.userDirs.createDirectories = lib.mkForce false;

  my = {
    shell = {
      elvish.enable = false;
      gpgTtyFix = false;
      xtermFix = true;
    };

    docs = {
      enable = true;
      prefix = "nixos";
    };

    development = {
      gh = false;
      rust = false;
      typescript = false;
    };
  };
}
