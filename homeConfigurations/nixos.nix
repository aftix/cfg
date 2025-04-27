# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{lib, ...}: {
  imports = [
    ../extraHomemanagerModules/sops.nix

    ../extraHomemanagerModules/development.nix
    ../extraHomemanagerModules/helix.nix
    ../extraHomemanagerModules/neoutils.nix
  ];

  xdg.userDirs.createDirectories = lib.mkForce false;

  my = {
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
