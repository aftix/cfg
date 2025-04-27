# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
let
  inputs = import ./inputs.nix;
  inherit (inputs) resolvers;
in
  inputs.nixputs.schemas.flake.overrideResolvers resolvers
