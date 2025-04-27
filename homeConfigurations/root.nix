{lib, ...}: {
  imports = [
    ../extraHomemanagerModules/sops.nix

    ../extraHomemanagerModules/helix.nix
    ../extraHomemanagerModules/neoutils.nix
  ];

  home = {
    username = "root";
    homeDirectory = "/root";
    stateVersion = "23.11"; # DO NOT CHANGE
  };

  xdg.userDirs.createDirectories = lib.mkForce false;

  my.shell.elvish.enable = true;
}
