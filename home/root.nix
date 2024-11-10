{lib, ...}: {
  imports = [
    ./common

    ./opt/sops.nix

    ./opt/helix.nix
    ./opt/neoutils.nix
  ];

  home = {
    username = "root";
    homeDirectory = "/root";
    stateVersion = "23.11"; # DO NOT CHANGE
  };

  xdg.userDirs.createDirectories = lib.mkForce false;

  my.shell.elvish.enable = true;
}
