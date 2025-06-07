# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../extraHomemanagerModules/sops.nix

    ../extraHomemanagerModules/development.nix
    ../extraHomemanagerModules/helix.nix
    ../extraHomemanagerModules/neoutils.nix
    ../extraHomemanagerModules/stylix.nix
  ];

  home = {
    username = "aftix";
    homeDirectory = "/home/aftix";
    packages = with pkgs; [attic-client kitty.terminfo];
    stateVersion = "23.11"; # DO NOT CHANGE
  };

  xdg.userDirs.createDirectories = lib.mkForce false;

  aftix = {
    shell = {
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
