# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{inputs ? import ./inputs.nix, ...}: {
  inherit (inputs.sops-nix.homeManagerModules) sops;
  inherit (inputs.stylix.homeManagerModules) stylix;
}
