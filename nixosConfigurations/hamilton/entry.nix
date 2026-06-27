# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{inputs, ...}: {
  entrypoint = ./configuration.nix;
  users = {
    aftix = import ../../homeConfigurations/aftix.nix;
    root = import ../../homeConfigurations/root.nix;
  };
  extraMods = [
    inputs.disko.nixosModules.disko
    inputs.lanzaboote.nixosModules.lanzaboote
  ];
}
