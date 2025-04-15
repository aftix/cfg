{
  inputs ? (import ./.).inputs,
  system ? builtins.currentSystem or "unknown-system",
  supportedSystems ? ["x86_64-linux"],
  scrubJobs ? true,
  pkgsCfg ? import ./nixpkgs-cfg.nix {inherit inputs;},
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

  inherit (release-lib) pkgs mapTestOn lib;
  inherit (lib) concatMapAttrs;

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
          val
          // {
            meta =
              (val.meta or {})
              // {
                inherit maintainers;
                description = "Build job for legacyPackages.${lib.last path}.${lib.concatStringsSep "." (lib.dropEnd 1 path)}";
                homepage = "https://forgejo.aftix.xyz/aftix/cfg";
              };
          });

    packageJobs = packagePlatforms ((import ./packages.nix {
        inherit inputs pkgs;
        overlay = _: _: {};
      })
      // {inherit (pkgs) lix;});
    nixosJobs =
      concatMapAttrs (name: cfg: {
        "nixos-configuration-${name}" =
          cfg.config.system.build.toplevel
          // {
            meta = {
              inherit maintainers;
              description = "Build job for nixos configuration ${name}";
              homepage = "https://forgejo.aftix.xyz/aftix/cfg";
              schedulingPriority = 50;
              license = lib.licenses.eupl12;
            };
          };
      })
      inputs.self.nixosConfigurations;
  in
    lib.attrsets.unionOfDisjoint (addHydraMeta (mapTestOn packageJobs)) nixosJobs;
in
  jobs
