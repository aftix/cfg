# Transform the fetched inputs into the schema
# this repo expects from the inputs
let
  rawInputs = import ./raw-inputs.nix;
  inherit (rawInputs) lib;
in
  lib.fix (
    inputs: let
      myLib = import ../lib.nix inputs;
      extraSpecialArgs = import ../extraSpecialArgs.nix {inherit inputs;};
      pkgsCfg = import ../nixpkgs-cfg.nix {
        inherit inputs myLib;
        overlay = inputs.self.overlays.default;
      };

      # Get "lib" flake output from flake-utils
      flake-utils = {
        lib = import "${rawInputs.flake-utils}/lib.nix" {
          defaultSystems = import rawInputs.nix-systems;
        };
      };

      # get the "lib" flake output from deploy-rs
      deploy-rs-flake = import "${rawInputs.deploy-rs}/flake.nix";
      deploy-rs = lib.fix (
        deploy-rs-self:
          deploy-rs-flake.outputs {
            self = deploy-rs-self;
            inherit flake-utils;
            inherit (inputs) nixpkgs;
          }
      );

      # Get the outputs from nix-index-database
      nix-index-database-flake = import "${rawInputs.nix-index-database}/flake.nix";
      nix-index-database = lib.fix (nix-index-self:
        nix-index-database-flake.outputs {
          self = nix-index-self;
          inherit (inputs) nixpkgs;
        });

      # Get packages from attic
      attic-packages = myLib.forEachSystem (
        system: let
          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              (final: _:
                {
                  craneLib = import rawInputs.crane {pkgs = final;};
                }
                // (import "${rawInputs.crane}/pkgs" {
                  pkgs = final;
                  myLib = final.craneLib;
                }))
            ];
          };

          atticPkgs = pkgs.callPackage "${rawInputs.attic}/crane.nix" {};
        in {
          inherit (atticPkgs) attic attic-client attic-server;
        }
      );
    in {
      # inputs.self is expected to contain the modules, configurations,
      # deploy configurations, packages, and overlays
      self = {
        nixosModules = import ../nixosModules.nix {
          inherit inputs myLib pkgsCfg;
          overlay = inputs.self.overlays.default;
        };
        homemanagerModules = import ../homemanagerModules.nix {
          inherit inputs myLib pkgsCfg;
          inherit (inputs.self) overlay;
        };

        overlays.default = import ../overlay.nix inputs;

        legacyPackages = myLib.forEachSystem (system:
          import ../packages.nix {
            inherit inputs myLib pkgsCfg system;
            overlay = inputs.self.overlays.default;
          });

        nixosConfigurations = import ../nixosConfigurations.nix {
          inherit inputs myLib extraSpecialArgs;
        };
        deploy = import ../deploy.nix {inherit (inputs) deploy-rs;};
      };

      inherit (rawInputs) carapace hostsBlacklist nginxBlacklist hyprland;
      inherit flake-utils deploy-rs nix-index-database;
      attic = {
        packages = attic-packages;
        overlays.default = final: _: {
          inherit (inputs.attic.packages.${final.hostPlatform.system}) attic attic-client attic-server;
        };
      };
      lanzaboote = import rawInputs.lanzaboote;
      srvos = import rawInputs.srvos;
      stylix = import rawInputs.stylix;
      nixos-cli = import rawInputs.nixos-cli;
      nixpkgs = let
        # The nixpkgs flake adds this to lib
        nixpkgsNode = rawInputs.lockFile.nodes.root.inputs.nixpkgs;
        libVersionInfoOverlay = import "${rawInputs.nixpkgs}/lib/flake-version-info.nix" {
          lastModifiedDate = myLib.formatSecondsSinceEpoch rawInputs.lockFile.nodes.${nixpkgsNode}.locked.lastModified;
          rev = rawInputs.lockFile.nodes.${nixpkgsNode}.locked.rev;
        };
      in {
        outPath = builtins.toString rawInputs.nixpkgs;

        # nixpkgs flake exposes per-system instatiated nixpkgs under legacyPackages
        legacyPackages = myLib.forEachSystem (
          system: let
            pkgs = import rawInputs.nixpkgs {inherit system;};
          in
            pkgs.extend libVersionInfoOverlay
        );

        # Add the non-nixpkgs functions to lib (that the nixpkgs flake output has as well)
        # Taken from https://github.com/nixos/nixpkgs
        # MIT Licensed
        lib =
          (rawInputs.lib.extend
            (final: prev: {
              nixos = import "${rawInputs.nixpkgs}/nixos/lib" {lib = final;};

              nixosSystem = args:
                import "${rawInputs.nixpkgs}/nixos/lib/eval-config.nix" (
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
                          config.nixpkgs.flake.source = ../.;
                        })
                      ];
                  }
                  // builtins.removeAttrs args ["modules"]
                );
            }))
          .extend
          libVersionInfoOverlay;
      };

      nur.overlays.default = final: prev: {
        nur = import rawInputs.nur {
          nurpkgs = prev;
          pkgs = prev;
        };
      };

      lix-module.overlays.default = import "${rawInputs.lix-module}/overlay.nix" {
        inherit (rawInputs) lix;
        versionSuffix = let
          lixVersionJson = builtins.fromJSON (builtins.readFile "${rawInputs.lix}/version.json");
          lixNodeName = rawInputs.lockFile.nodes.root.inputs.lix;
          lix = rawInputs.lockFile.nodes.${lixNodeName}.locked;
          lastModifiedDate = myLib.formatSecondsSinceEpoch lix.lastModified;
        in
          inputs.nixpkgs.lib.optionalString (!lixVersionJson.official_release)
          "-pre${builtins.substring 0 8 lastModifiedDate}-${builtins.substring 0 7 lix.rev}";
      };

      home-manager = {
        outPath = "${rawInputs.home-manager}";
        lib = import "${rawInputs.home-manager}/lib" {inherit (inputs.nixpkgs) lib;};
        nixosModules = let
          home-manager = "${rawInputs.home-manager}/nixos";
        in {
          inherit home-manager;
          default = home-manager;
        };
      };

      disko.nixosModules = let
        disko = "${rawInputs.disko}/module.nix";
      in {
        inherit disko;
        default = disko;
      };

      preservation.nixosModules = let
        preservation = import "${rawInputs.preservation}/module.nix";
      in {
        inherit preservation;
        default = preservation;
      };

      sops-nix = {
        nixosModules = let
          sops = "${rawInputs.sops-nix}/modules/sops";
        in {
          inherit sops;
          default = sops;
        };
        homeManagerModules = let
          sops = "${rawInputs.sops-nix}/modules/home-manager/sops.nix";
        in {
          inherit sops;
          default = sops;
        };
      };
    }
  )
