# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  lib,
  myLib,
}: {
  crane = {
    name,
    source,
    ...
  }:
    lib.flake.getSourceInfo {inherit name source;};

  attic = {
    name,
    source,
    inputs,
  }: let
    fetched = lib.flake.getSourceInfo {inherit name source;};

    packages = myLib.forEachSystem (
      system: let
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            (final: _:
              {
                craneLib = import inputs."attic/crane" {pkgs = final;};
              }
              // (import "${inputs."attic/crane"}/pkgs" {
                pkgs = final;
                myLib = final.craneLib;
              }))
          ];
        };

        atticPkgs = pkgs.callPackage "${fetched}/crane.nix" {};
      in {
        inherit (atticPkgs) attic attic-client attic-server;
      }
    );
  in
    fetched
    // {
      inherit packages;
      overlays.default = final: _: {
        inherit (packages.${final.hostPlatform.system}) attic attic-client attic-server;
      };
    };

  nixpkgs = {
    name,
    source,
    ...
  }: let
    fetched = lib.flake.getSourceInfo {inherit name source;};
    libVersionInfoOverlay = import "${fetched}/lib/flake-version-info.nix" {
      inherit (fetched) lastModifiedDate rev;
    };
  in
    fetched
    // {
      legacyPackages = myLib.forEachSystem (
        system: let
          pkgs = import fetched {inherit system;};
        in
          pkgs.extend libVersionInfoOverlay
      );

      # Add the non-nixpkgs functions to lib (that the nixpkgs flake output has as well)
      # Taken from https://github.com/nixos/nixpkgs
      # MIT Licensed
      lib =
        ((import "${fetched}/lib").extend (final: prev: {
          nixos = import "${fetched}/nixos/lib" {lib = final;};

          nixosSystem = args:
            import "${fetched}/nixos/lib/eval-config.nix" (
              {
                lib = final;
                # Allow system to be set modularly in nixpkgs.system.
                # We set it to null, to remove the "legacy" entrypoint's
                # non-hermetic default.
                system = null;

                modules =
                  args.modules
                  ++ [
                    ({...}: {
                      config.nixpkgs.flake.source = builtins.toString fetched;
                    })
                  ];
              }
              // builtins.removeAttrs args ["modules"]
            );
        })).extend
        libVersionInfoOverlay;
    };

  nur = {
    name,
    source,
    ...
  }: let
    fetched = lib.flake.getSourceInfo {inherit name source;};
  in
    fetched
    // {
      overlays.default = final: prev: {
        nur = import fetched.outPath {
          nurpkgs = prev;
          pkgs = prev;
        };
      };
    };

  home-manager = {
    name,
    source,
    inputs,
  }: let
    fetched = lib.flake.getSourceInfo {inherit name source;};
  in
    fetched
    // {
      lib = import "${fetched}/lib" {inherit (inputs.nixpkgs) lib;};
      nixosModules = let
        home-manager = "${fetched}/nixos";
      in {
        inherit home-manager;
        default = home-manager;
      };
    };

  disko = {
    name,
    source,
    ...
  }: let
    fetched = lib.flake.getSourceInfo {inherit name source;};
  in
    fetched
    // {
      nixosModules = let
        disko = "${fetched}/module.nix";
      in {
        inherit disko;
        default = disko;
      };
    };

  preservation = {
    name,
    source,
    ...
  }: let
    fetched = lib.flake.getSourceInfo {inherit name source;};
  in
    fetched
    // {
      nixosModules = let
        preservation = "${fetched}/module.nix";
      in {
        inherit preservation;
        default = preservation;
      };
    };

  sops-nix = {
    name,
    source,
    ...
  }: let
    fetched = lib.flake.getSourceInfo {inherit name source;};
  in
    fetched
    // {
      nixosModules = let
        sops = "${fetched}/modules/sops";
      in {
        inherit sops;
        default = sops;
      };

      homeManagerModules = let
        sops = "${fetched}/modules/home-manager/sops.nix";
      in {
        inherit sops;
        default = sops;
      };
    };
}
