# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
let
  sources = import ./npins {};

  libVersionInfoOverlay = import "${sources.nixpkgs}/lib/flake-version-info.nix" {
    rev = sources.nixpkgs.revision;
  };
  nixpkgsLib = (import "${sources.nixpkgs}/lib").extend libVersionInfoOverlay;

  mkModulesInner = {
    name,
    path ? "module.nix",
    attrName ? name,
  }: let
    pin = builtins.getAttr name sources;
    pinModule = "${pin}/${path}";
  in
    pin
    // {
      nixosModules = {
        "${attrName}" = pinModule;
        default = pinModule;
      };
    };

  mkModules = name:
    (mkModulesInner {inherit name;})
    // {
      __functor = _: path:
        (mkModulesInner {inherit name path;})
        // {
          __functor = _: attrName: mkModulesInner {inherit name path attrName;};
        };
    };

  mkInputs = sources:
    nixpkgsLib.makeExtensibleWithCustomName "override" (self: let
      nixpkgsLib = (import "${sources.nixpkgs}/lib").extend libVersionInfoOverlay;

      libVersionInfoOverlay = import "${sources.nixpkgs}/lib/flake-version-info.nix" {
        rev = sources.nixpkgs.revision;
      };
    in
      {
        inherit sources;
        overrideSources = overlay: mkInputs (sources.override (nixpkgsLib.toExtension overlay));

        attic = let
          packages = myLib.forEachSystem (
            system: let
              pkgs = import self.nixpkgs {
                inherit system;
                overlays = [
                  (
                    final: _:
                      {
                        craneLib = import self.crane {pkgs = final;};
                      }
                      // (import "${self.crane}/pkgs" {
                        pkgs = final;
                        myLib = final.craneLib;
                      })
                  )
                ];
              };

              atticPkgs = pkgs.callPackage "${sources.attic}/crane.nix" {};
            in {
              inherit (atticPkgs) attic attic-client attic-server;
            }
          );
        in {
          inherit packages;
        };

        disko = mkModules "disko";
        home-manager =
          (mkModules "home-manager" "nixos")
          // {
            lib = import "${sources.home-manager}/lib" {
              inherit (self.nixpkgs) lib;
            };
          };

        lanzaboote = import sources.lanzaboote {};

        nixpkgs =
          sources.nixpkgs
          // {
            legacyPackages = myLib.forEachSystem (
              system: let
                pkgs = import sources.nixpkgs {inherit system;};
              in
                pkgs.extend libVersionInfoOverlay
            );

            # Add the non-nixpkgs functions to lib (that the nixpkgs flake output has as well)
            # Taken from https://github.com/nixos/nixpkgs
            # MIT Licensed
            lib = nixpkgsLib.extend (final: prev: {
              nixos = import "${sources.nixpkgs}/nixos/lib" {lib = final;};

              nixosSystem = args:
                import "${sources.nixpkgs}/nixos/lib/eval-config.nix" (
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
                          config.nixpkgs.flake.source = toString sources.nixpkgs;
                        })
                      ];
                  }
                  // removeAttrs args ["modules"]
                );
            });
          };

        nixcord =
          (mkModules "nixcord")
          // {
            homeModules = let
              nixcordPkgs = pkgs: let
                discordAvailable = pkgs.lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.discord;
                docsSystems = [
                  "x86_64-linux"
                  "aarch64-darwin"
                ];
                docsArtifacts = import "${sources.nixcord}/docs" {
                  inherit pkgs;
                  inherit (pkgs) lib;
                  inherit (sources.nixcord) revision;
                };
              in
                (pkgs.lib.optionalAttrs discordAvailable {
                  discord = pkgs.callPackage "${sources.nixcord}/pkgs/discord" {};
                  discord-ptb = pkgs.callPackage "${sources.nixcord}/pkgs/discord" {branch = "ptb";};
                  discord-canary = pkgs.callPackage "${sources.nixcord}/pkgs/discord" {branch = "canary";};
                  discord-development = pkgs.callPackage "${sources.nixcord}/pkgs/discord" {branch = "development";};
                })
                // (pkgs.lib.optionalAttrs (builtins.elem pkgs.stdenv.hostPlatform.system docsSystems) {
                  docs =
                    docsArtifacts.html;
                })
                // {
                  vencord = pkgs.callPackage "${sources.nixcord}/pkgs/vencord.nix" {};
                  vencord-unstable = pkgs.callPackage "${sources.nixcord}/pkgs/vencord.nix" {unstable = true;};
                  equicord = pkgs.callPackage "${sources.nixcord}/pkgs/equicord.nix" {};
                  generate = pkgs.callPackage "${sources.nixcord}/pkgs/generate-options.nix" {};
                  docs-json = docsArtifacts.json;
                };

              nixcord = {pkgs, ...}: {
                imports = ["${sources.nixcord}/modules/hm"];
                _module.args.nixcordPkgs = nixcordPkgs pkgs;
              };
            in {
              inherit nixcord;
              default = nixcord;
            };
          };

        nix-index-database =
          (mkModules "nix-index-database" "nixos-module.nix" "nix-index")
          // {
            homeModules = let
              nix-index = "${sources.nix-index-database}/home-manager-module.nix";
            in {
              inherit nix-index;
              default = nix-index;
            };
          };

        nur =
          sources.nur
          // {
            overlays.default = final: prev: {
              nur = import sources.nur {
                nurpkgs = prev;
                pkgs = prev;
              };
            };
          };

        preservation = mkModules "preservation";
        sops-nix =
          (mkModules "sops-nix" "modules/sops" "sops")
          // {
            homeManagerModules = let
              sops = "${sources.sops-nix}/modules/home-manager/sops.nix";
            in {
              inherit sops;
              default = sops;
            };
          };
        srvos = sources.srvos // (import sources.srvos);
        stylix = import sources.stylix;
      }
      // (nixpkgsLib.getAttrs [
          "hostsBlacklist"
          "nginxBlacklist"
          "hydra"
        ]
        sources));

  # bootstrap ./lib
  myLib = import ./lib.nix {
    inputs = {nixpkgs = {lib = nixpkgsLib;};};
  };
in
  mkInputs (nixpkgsLib.makeExtensibleWithCustomName "override" (_: sources))
