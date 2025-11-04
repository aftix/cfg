# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  description = "Aftix's NixOS configuration";

  inputs = {
    nixputs = {
      url = "https://forge.aftix.xyz/aftix/nixputs/archive/main.tar.gz";
      flake = false;
    };

    hydra = {
      url = "https://git.lix.systems/lix-project/hydra/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    srvos = {
      url = "github:numtide/srvos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    preservation.url = "github:willibutz/preservation";
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hostsBlacklist = {
      url = "github:Ultimate-Hosts-Blacklist/Ultimate.Hosts.Blacklist";
      flake = false;
    };
    nginxBlacklist = {
      url = "github:mitchellkrogza/nginx-ultimate-bad-bot-blocker";
      flake = false;
    };

    hyprland = {
      url = "github:hyprwm/hyprland";
      flake = false; # Just want the wallpaper image
    };
  };

  outputs = inputs: let
    myLib = import ./lib.nix {
      inherit inputs pkgsCfg;
      inherit (inputs.self) nixosModules homemanagerModules;
    };

    nixSettings = import ./nix-settings.nix;
    overlay = import ./overlay.nix {inherit inputs myLib;};
    pkgsCfg = import ./nixpkgs-cfg.nix {inherit inputs myLib overlay;};
    extraSpecialArgs = import ./extraSpecialArgs.nix {inherit inputs;};
  in {
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

    legacyPackages = myLib.forEachSystem (system:
      import ./packages.nix {
        inherit inputs pkgsCfg system;
      });

    devShells = myLib.forEachSystem (system: {
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
}
