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
                nix = final.nixVersions.nix_2_24;
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

  lix = {source, ...} @ args: let
    fetched = lib.flake.defaultResolver args;
    versionJson = builtins.fromJSON (builtins.readFile "${fetched}/version.json");

    sourceInfo = {
      official_release = versionJson.official_release;
      inherit (source.locked) lastModified rev;
      lastModifiedDate = lib.formatSecondsSinceEpoch source.locked.lastModified;
      versionSuffix =
        if versionJson.official_release
        then ""
        else "-pre${builtins.substring 0 8 sourceInfo.lastModifiedDate}-${builtins.substring 0 7 sourceInfo.rev}";
    };
  in
    fetched
    // sourceInfo
    // {
      sourceInfo = (fetched.sourceInfo or {}) // sourceInfo;
    };

  lix-module = {
    name,
    source,
    inputs,
  }: let
    fetched = lib.flake.getSourceInfo {inherit name source;};
  in
    fetched
    // {
      overlays.default = import "${fetched}/overlay.nix" {
        inherit (inputs) lix;
        inherit (inputs.lix) versionSuffix;
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
