# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{inputs, ...}: {
  entrypoint = ./configuration.nix;
  users = {
    aftix = import ../../homeConfigurations/aftix-minimal.nix;
    root = import ../../homeConfigurations/root.nix;
  };
  extraMods = [
    inputs.srvos.nixosModules.server
    inputs.srvos.nixosModules.mixins-nginx
  ];
}
