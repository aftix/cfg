# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  inputs ? import ./inputs.nix,
  myLib ? import ./lib.nix {inherit inputs;},
  nixosConfigurations ? import ./nixosConfigurations.nix {inherit inputs myLib;},
  system ? builtins.currentSystem or "unknown-system",
  supportedSystems ? ["x86_64-linux"],
  scrubJobs ? true,
  pkgsCfg ? import ./nixpkgs-cfg.nix {inherit inputs myLib;},
  nixpkgsArgs ? {
    config =
      pkgsCfg.nixpkgs.config
      // {
        inHydra = true;
      };
    inherit (pkgsCfg.nixpkgs) overlays;
  },
  ...
}: let
  release-lib = import "${inputs.nixpkgs}/pkgs/top-level/release-lib.nix" {
    inherit supportedSystems scrubJobs nixpkgsArgs system;
  };

  pkgsForChecks = lib.packagesFromDirectoryRecursive {
    inherit (pkgs) callPackage;
    directory = ./checks;
  };

  inherit (release-lib) pkgs mapTestOn lib;

  maintainers = [
    {
      email = "aftix@aftix.xyz";
    }
  ];

  jobs = let
    packagePlatforms = release-lib.recursiveMapPackages release-lib.getPlatforms;

    addHydraMeta =
      lib.attrsets.mapAttrsRecursiveCond (as: ! lib.isDerivation as)
      (path: val:
        if ! lib.isDerivation val
        then val
        else
          lib.recursiveUpdate val
          {
            meta = {
              inherit maintainers;
              description = "Build job for legacyPackages.${lib.last path}.${lib.concatStringsSep "." (lib.dropEnd 1 path)}";
              homepage = "https://forgejo.aftix.xyz/aftix/cfg";
            };
          });

    packageJobs = packagePlatforms (import ./packages.nix {
      inherit inputs pkgs;
      overlay = _: _: {};
    });
    nixosJobs = {
      nixos-configurations = lib.mapAttrs (name: cfg:
        cfg.config.system.build.toplevel
        // {
          meta = {
            inherit maintainers;
            description = "Build job for nixos configuration ${name}";
            homepage = "https://forgejo.aftix.xyz/aftix/cfg";
            schedulingPriority = 200;
            license = lib.licenses.eupl12;
          };
        })
      nixosConfigurations;
    };

    mkCheckJob = path: packageSet: let
      joinedPath = lib.concatStringsSep "/" path;
      pkgSpeculativePath = ./checks/${joinedPath};
      contents = builtins.readDir (builtins.dirOf pkgSpeculativePath);
      pkgBaseName = builtins.baseNameOf pkgSpeculativePath;
      pkgPath =
        if builtins.hasAttr (pkgBaseName + ".nix") contents
        then ./checks/${joinedPath + ".nix"}
        else ./checks/${joinedPath}/package.nix;
      newlyCalled = packageSet.callPackage pkgPath {};
      pkg =
        if packageSet.stdenv.hostPlatform == pkgs.stdenv.hostPlatform
        then lib.getAttrFromPath path pkgsForChecks
        else newlyCalled;
    in
      lib.recursiveUpdate pkg {
        meta = {
          inherit maintainers;
          license = lib.licenses.eupl12;
          homepage = "https://forge.aftix.xyz/aftix/cfg";
        };
      };

    checkJobs = {
      checks = lib.mapAttrsRecursive (path: platforms: release-lib.testOn platforms (mkCheckJob path)) (release-lib.packagePlatforms pkgsForChecks);
    };
  in
    lib.attrsets.unionOfDisjoint (lib.attrsets.unionOfDisjoint (addHydraMeta (mapTestOn packageJobs)) nixosJobs) checkJobs;
in
  jobs
