# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
let
  pkgsCfgFn = import ./nixpkgs-cfg.nix;
  myLibFn = import ./lib.nix;
  nixSettings = import ./nix-settings.nix;
  overlayFn = import ./overlay.nix;
  extraSpecialArgsFn = import ./extraSpecialArgs.nix;

  mkSelf = inputs: let
    pkgsCfg = pkgsCfgFn {inherit inputs myLib overlay;};
    myLib = myLibFn {
      inherit inputs pkgsCfg;
      inherit (self) nixosModules homemanagerModules;
    };
    overlay = overlayFn {inherit inputs myLib;};
    extraSpecialArgs = extraSpecialArgsFn {inherit inputs;};

    self = {
      inherit inputs;
      overrideInputs = ext: mkSelf (inputs.override (inputs.nixpkgs.lib.toExtension ext));
      overrideSources = ext: mkSelf (inputs.overrideSources (inputs.nixpkgs.lib.toExtension ext));

      overlays.default = overlay;

      nixosConfigurations = import ./nixosConfigurations.nix {inherit inputs pkgsCfg myLib extraSpecialArgs;};
      nixosModules = import ./nixosModules.nix {inherit inputs pkgsCfg myLib;};
      homemanagerModules = import ./homemanagerModules.nix {inherit inputs pkgsCfg myLib;};

      extra = {
        # NOTE: you'll need to use these for some optional modules
        inherit extraSpecialArgs;

        inherit
          (nixSettings)
          substituters
          trusted-public-keys
          extra-experimental-features
          ;
      };

      lib = myLib;

      formatter = myLib.forEachSystem (sys: let
        pkgs = inputs.nixpkgs.legacyPackages.${sys};
      in
        pkgs.alejandra or pkgs.nix-fmt);

      packages = myLib.forEachSystem (system:
        import ./packages.nix {
          inherit inputs pkgsCfg system;
        });

      shells = myLib.forEachSystem (system: {
        default = import ./shell.nix {
          inherit system pkgsCfg inputs;
        };
      });

      nodes = import ./nodes.nix;

      hydraJobs = import ./hydraJobs.nix {
        inherit inputs pkgsCfg;
        system = "x86_64-linux";
      };
    };
  in
    self;
in
  mkSelf (import ./inputs.nix)
