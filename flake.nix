{
  description = "Aftix's NixOS configuration";

  inputs = {
    lix = {
      url = "https://git.lix.systems/lix-project/lix/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/main.tar.gz";
      inputs = {
        lix.follows = "lix";
        nixpkgs.follows = "nixpkgs";
      };
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

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
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
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-cli.url = "github:water-sucks/nixos";

    carapace = {
      url = "github:carapace-sh/carapace-bin";
      flake = false;
    };

    attic.url = "github:zhaofengli/attic";

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

  outputs = {
    self,
    nixpkgs,
    nur,
    deploy-rs,
    flake-utils,
    ...
  } @ inputs: let
    myLib = import ./lib.nix inputs;
    nixSettings = import ./nix-settings.nix;
    overlay = import ./overlay.nix inputs;
    pkgsCfg = import ./nixpkgs-cfg.nix {inherit inputs overlay;};
    extraSpecialArgs = import ./extraSpecialArgs.nix {inherit inputs;};
  in
    {
      overlays.default = overlay;

      nixosConfigurations = myLib.nixosConfigurationsFromDirectoryRecursive {
        directory = ./nixosConfigurations;
        dep-injects = myLib.dependencyInjects {
          extraInject = {commonHmModules = self.homemanagerModules.commonModules;};
        };
        inherit extraSpecialArgs;
      };

      deploy.nodes.fermi = {
        hostname = "170.130.165.174";
        profiles.system = {
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.fermi;
        };
      };

      nixosModules = import ./nixosModules.nix {
        inherit inputs overlay myLib pkgsCfg;
      };

      homemanagerModules = import ./homemanagerModules.nix {
        inherit inputs overlay myLib pkgsCfg;
      };

      extra = {
        # NOTE: you'll need to use these for some optional modules
        inherit extraSpecialArgs myLib;

        inherit
          (nixSettings)
          substituters
          trusted-public-keys
          extra-experimental-features
          ;
      };
    }
    // flake-utils.lib.eachDefaultSystem (sys: let
      pkgs = import nixpkgs {
        system = sys;
        inherit (pkgsCfg.nixpkgs) config;
        overlays = [
          nur.overlays.default
          (_: _: {inherit (inputs) nginxBlacklist;})
        ];
      };
    in {
      formatter =
        pkgs.alejandra or pkgs.nix-fmt;

      checks = nixpkgs.lib.attrsets.optionalAttrs (deploy-rs.lib ? "${sys}") (deploy-rs.lib.${sys}.deployChecks self.deploy);

      legacyPackages = import ./packages.nix {
        inherit inputs overlay pkgsCfg;
        system = sys;
      };
    });
}
