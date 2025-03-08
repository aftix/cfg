# Transform the fetched inputs into the schema
# this repo expects from the inputs
let
  rawInputs = import ./raw-inputs.nix;
  inherit (rawInputs) lib;

  thisFlake = import ../flake.nix;
  makeInputsExtensible = import ../lib/makeInputsExtensible.nix lib;
in
  makeInputsExtensible (
    inputs: let
      myLib = inputs.self.lib;
    in {
      # This will do the same fixed point magic as a normal self input for a flake instantiation
      # This way, we only have to figure out how to import all the inputs, not set up the flake schema again
      self = thisFlake.outputs inputs;

      nix-index-database = myLib.getFlakeOutputs rawInputs.nix-index-database {inherit (inputs) nixpkgs;};

      inherit (rawInputs) carapace hostsBlacklist nginxBlacklist hyprland;

      attic = {
        outPath = builtins.toString rawInputs.attic;
        packages = myLib.forEachSystem (
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
        overlays.default = final: _: {
          inherit (inputs.attic.packages.${final.hostPlatform.system}) attic attic-client attic-server;
        };
      };

      lanzaboote = (import rawInputs.lanzaboote) // {outPath = builtins.toString rawInputs.lanzaboote;};
      srvos = (import rawInputs.srvos) // {outPath = builtins.toString rawInputs.srvos;};
      stylix = (import rawInputs.stylix) // {outPath = builtins.toString rawInputs.stylix;};
      lix = (import rawInputs.lix) // {outPath = builtins.toString rawInputs.lix;};
      hydra = import rawInputs.hydra // {outPath = builtins.toString rawInputs.hydra;};

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
                          config.nixpkgs.flake.source = builtins.toString rawInputs.nixpkgs;
                        })
                      ];
                  }
                  // builtins.removeAttrs args ["modules"]
                );
            }))
          .extend
          libVersionInfoOverlay;
      };

      nur = {
        outPath = builtins.toString rawInputs.nur;
        overlays.default = final: prev: {
          nur = import rawInputs.nur {
            nurpkgs = prev;
            pkgs = prev;
          };
        };
      };

      lix-module = {
        outPath = builtins.toString rawInputs.lix-module;
        overlays.default = import "${rawInputs.lix-module}/overlay.nix" {
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
      };

      home-manager = {
        outPath = builtins.toString rawInputs.home-manager;
        lib = import "${rawInputs.home-manager}/lib" {inherit (inputs.nixpkgs) lib;};
        nixosModules = let
          home-manager = "${rawInputs.home-manager}/nixos";
        in {
          inherit home-manager;
          default = home-manager;
        };
      };

      disko = {
        outPath = builtins.toString rawInputs.disko;
        nixosModules = let
          disko = "${rawInputs.disko}/module.nix";
        in {
          inherit disko;
          default = disko;
        };
      };

      preservation = {
        outPath = builtins.toString rawInputs.preservation;
        nixosModules = let
          preservation = import "${rawInputs.preservation}/module.nix";
        in {
          inherit preservation;
          default = preservation;
        };
      };

      sops-nix = {
        outPath = builtins.toString rawInputs.sops-nix;
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
