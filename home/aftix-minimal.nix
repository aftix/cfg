{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./common

    ./opt/sops.nix

    ./opt/development.nix
    ./opt/helix.nix
    ./opt/neoutils.nix
    ./opt/stylix.nix
  ];

  home = {
    username = "aftix";
    homeDirectory = "/home/aftix";
    sessionVariables = rec {
      TERM = "xterm";
      TERMINAL = TERM;
    };
    packages = with pkgs; [attic-client];

    stateVersion = "23.11"; # DO NOT CHANGE
  };

  xdg.userDirs.createDirectories = lib.mkForce false;

  my = {
    shell = {
      elvish.enable = false;
      nushell.enable = false;
      xtermFix = true;
      gpgTtyFix = false;
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
