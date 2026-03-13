# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  inputs ? import ../inputs.nix,
  myLib ? import ../lib.nix {inherit inputs;},
  pkgsCfg ? import ../nixpkgs-cfg.nix {inherit inputs myLib;},
  system ? builtins.currentSystem or "unknown-system",
  crossSystem ? null,
  pkgs ?
    import inputs.nixpkgs (
      inputs.nixpkgs.lib.recursiveUpdate {
        inherit system;
        inherit (pkgsCfg.nixpkgs) config overlays;
      }
      (inputs.nixpkgs.lib.optionalAttrs (crossSystem != null) {inherit crossSystem;})
    ),
  ...
}: let
  inherit (pkgs) lib;
  # Get repo packages
  packages = import ../packages.nix {inherit inputs myLib pkgsCfg system pkgs;};
  convert = prefix:
    lib.mapAttrsToList (name: value: let
      fullname = "${prefix}${lib.optionalString (prefix != "") "."}${name}";
    in
      if lib.isAttrs value && !lib.isDerivation value
      then convert fullname value
      else fullname);
in
  lib.pipe packages [
    (
      lib.concatMapAttrs (name: value:
        if lib.isDerivation value
        then {${name} = value;}
        else if lib.isAttrs value
        then {
          ${name} =
            lib.filterAttrs
            (
              name: value:
                lib.isDerivation value || value.recurseForDerivations or false
            )
            value;
        }
        else {})
    )
    (convert "")
    lib.flatten
    (lib.concatStringsSep " ")
  ]
