# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
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
