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
    home-manager,
    deploy-rs,
    flake-utils,
    ...
  } @ inputs: let
    myLib = import ./lib.nix inputs nixpkgs.lib;

    substituters = [
      "https://nix-community.cachix.org"
      "https://cache.nixos.org"
      "https://attic.aftix.xyz/cfg-actions"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cfg-actions:R9aJEQdcJT8NrUh1yox2FgZfmzRrKi6MAobbfuRvv3g="
    ];
    extra-experimental-features = [
      "nix-command"
      "flakes"
      "pipe-operator"
    ];

    overlay = import ./overlay.nix inputs;

    pkgsCfg = {
      nixpkgs = {
        overlays = [
          nur.overlays.default
          inputs.attic.overlays.default
          overlay
        ];
        config = {
          allowUnfreePredicate = pkg:
            builtins.elem (nixpkgs.lib.getName pkg) [
              "discord"
              "pay-by-privacy"
              "aspell-dict-en-science"
            ];

          permittedInsecurePackages = [
            "jitsi-meet-1.0.8043"
          ];
        };
      };
    };

    importNixosHomeOptions = {
      pkgs,
      lib,
      ...
    }: {options = import ./nixos-home-options.nix pkgs lib;};

    commonModules = [
      pkgsCfg
      ({
        lib,
        pkgs,
        ...
      }: {
        nix = {
          package = lib.mkForce pkgs.nix;
          settings = {inherit substituters trusted-public-keys;};
        };

        programs = {
          nix-index-database.comma.enable = true;
          command-not-found.enable = false;
        };

        nixpkgs.overlays = [
          inputs.lix-module.overlays.default
          (_: prev: {
            lix = prev.lix.override {aws-sdk-cpp = null;};
          })
        ];
      })
      home-manager.nixosModules.home-manager
      inputs.sops-nix.nixosModules.sops
      inputs.nix-index-database.nixosModules.nix-index
      inputs.srvos.nixosModules.mixins-trusted-nix-caches
      inputs.nixos-cli.nixosModules.nixos-cli
      inputs.preservation.nixosModules.default
      importNixosHomeOptions
    ];

    extraSpecialArgs = {
      inherit (inputs.sops-nix.homeManagerModules) sops;
      inherit (inputs.stylix.homeManagerModules) stylix;
    };

    commonHmModules = [
      pkgsCfg
      inputs.nix-index-database.hmModules.nix-index
      importNixosHomeOptions
      {
        programs = {
          nix-index-database.comma.enable = true;
          command-not-found.enable = false;
        };
      }
    ];
  in
    {
      overlays.default = overlay;

      nixosConfigurations = myLib.nixosConfigurationsFromDirectoryRecursive {
        directory = ./nixosConfigurations;
        dep-injects = myLib.dependencyInjects {
          extraInject = {inherit commonHmModules;};
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

      nixosModules =
        {
          default = {
            imports = commonModules ++ [./host/common];
          };
          nix-settings = {
            nix.settings = {inherit substituters trusted-public-keys extra-experimental-features;};
          };
        }
        // (myLib.modulesFromDirectoryRecursive ./host/opt);

      homemanagerModules =
        {
          default = {
            imports = commonHmModules ++ [./home/common];
          };
        }
        // (myLib.modulesFromDirectoryRecursive ./home/opt);

      extra = {
        # NOTE: you'll need to use these for some optional modules
        inherit extraSpecialArgs;

        inherit
          substituters
          trusted-public-keys
          extra-experimental-features
          myLib
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

      legacyPackages.freshrssExts =
        pkgs.lib.attrsets.recurseIntoAttrs (pkgs.callPackage ./legacyPackages/freshrss {});

      packages = let
        appliedOverlay = pkgs.extend self.overlays.default;
      in
        pkgs.lib.filesystem.packagesFromDirectoryRecursive {
          inherit (pkgs) callPackage;
          directory = ./packages;
        }
        // {
          inherit
            (appliedOverlay)
            carapace
            heisenbridge
            attic
            attic-client
            attic-server
            matrix-synapse-unwrapped
            pwvucontrol
            ;

          lix = inputs.lix-module.packages.${sys}.default.override {aws-sdk-cpp = null;};
        };
    });
}
