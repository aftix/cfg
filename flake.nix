{
  description = "Aftix's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    stablepkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nur.url = "github:nix-community/NUR";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs.url = "github:serokell/deploy-rs";

    flake-utils.url = "github:numtide/flake-utils";
    srvos = {
      url = "github:numtide/srvos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";
    stylix.url = "github:danth/stylix";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "stablepkgs";
      };
    };

    hyprland.url = "git+https://github.com/hyprwm/Hyprland/?rev=9e781040d9067c2711ec2e9f5b47b76ef70762b3&submodules=1";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins/v0.41.1";
      inputs.hyprland.follows = "hyprland";
    };

    waybar = {
      url = "github:Alexays/Waybar";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    coffeepaste = {
      url = "sourcehut:~mort/coffeepaste";
      flake = false;
    };
    barcodebuddy = {
      url = "github:Forceu/barcodebuddy/v1.8.1.7";
      flake = false;
    };

    freshrss-ext = {
      url = "github:FreshRSS/Extensions";
      flake = false;
    };
    freshrss-cntools = {
      url = "github:cn-tools/cntools_FreshRssExtensions";
      flake = false;
    };
    freshrss-latex = {
      url = "github:aledeg/xExtension-LatexSupport";
      flake = false;
    };
    freshrss-reddit = {
      url = "github:aledeg/xExtension-RedditImage";
      flake = false;
    };
    freshrss-ttl = {
      url = "github:mgnsk/FreshRSS-AutoTTL";
      flake = false;
    };
    freshrss-links = {
      url = "github:kapdap/freshrss-extensions";
      flake = false;
    };
    freshrss-ezpriorities = {
      url = "github:aidistan/freshrss-extensions";
      flake = false;
    };
    freshrss-ezread = {
      url = "github:kalvn/freshrss-mark-previous-as-read";
      flake = false;
    };
    freshrss-threepane = {
      url = "git+https://framagit.org/nicofrand/xextension-threepanesview.git";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    stablepkgs,
    nur,
    home-manager,
    deploy-rs,
    flake-utils,
    ...
  } @ inputs: let
    system = "x86_64-linux";

    overlay = final: prev: {
      coreutils-full = prev.uutils-coreutils-noprefix;

      stty = prev.writeShellApplication {
        name = "stty";
        runtimeInputs =
          if prev.lib.strings.hasSuffix "-linux" prev.system
          then [final.busybox]
          else [prev.coreutils];

        text = ''
          stty "$@"
        '';
      };

      znc = stablepkgs.legacyPackages.${final.system}.znc;
      freshrss = stablepkgs.legacyPackages.${final.system}.freshrss;
      clamav = stablepkgs.legacyPackages.${final.system}.clamav;
      fail2ban = stablepkgs.legacyPackages.${final.system}.fail2ban;
      transmission_4 = stablepkgs.legacyPackages.${final.system}.transmission_4;
    };

    pkgsCfg = {
      nixpkgs = {
        overlays = [
          nur.overlay
          inputs.waybar.overlays.default
          overlay
        ];
        config.allowUnfreePredicate = pkg:
          builtins.elem (nixpkgs.lib.getName pkg) [
            "discord"
            "pay-by-privacy"
            "aspell-dict-en-science"
          ];
      };
    };

    spkgs = stablepkgs.legacyPackages.${system};

    specialArgs = {
      inherit spkgs inputs;
      hyprPkgs = {
        inherit (inputs.hyprland.packages.${system}) hyprland hyprland-protocols xdg-desktop-portal-hyprland;
        inherit (inputs.hyprland-plugins.packages.${system}) hyprbars hyprexpo;
      };
    };
    extraSpecialArgs =
      specialArgs
      // {
        home-impermanence = inputs.impermanence.nixosModules.home-manager.impermanence;
        inherit (inputs.stylix.homeManagerModules) stylix;
        sops-nix = inputs.sops-nix.homeManagerModules.sops;
      };

    commonModules = [
      pkgsCfg
      home-manager.nixosModules.home-manager
      inputs.sops-nix.nixosModules.sops
      inputs.nix-index-database.nixosModules.nix-index
      inputs.srvos.nixosModules.mixins-nix-experimental
      inputs.srvos.nixosModules.mixins-trusted-nix-caches
      {
        programs = {
          nix-index-database.comma.enable = true;
          command-not-found.enable = false;
        };
      }
    ];

    commonHmModules = [
      pkgsCfg
      inputs.nix-index-database.hmModules.nix-index
      {
        programs = {
          nix-index-database.comma.enable = true;
          command-not-found.enable = false;
        };
      }
    ];

    isoCfgs = let
      inherit (nixpkgs.lib) nixosSystem;
    in
      flake-utils.lib.eachSystem ["x86_64-linux"] # TODO: figure out why nix flake check is unhappy with many systems here
      
      (
        isoSystem: {
          "iso-minimal" = nixosSystem {
            inherit specialArgs;

            modules =
              commonModules
              ++ [
                {nixpkgs.hostPlatform = isoSystem;}
                "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
                "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
                inputs.disko.nixosModules.disko
                inputs.impermanence.nixosModules.impermanence
                ./host/iso-minimal.nix

                {
                  home-manager = {
                    inherit extraSpecialArgs;
                    useUserPackages = true;

                    sharedModules = commonHmModules;

                    users = {
                      root = ./home/root.nix;
                      nixos = ./home/nixos.nix;
                    };
                  };
                }
              ];
          };

          "iso-graphical" = nixpkgs.lib.nixosSystem {
            inherit specialArgs;

            modules = [
              {nixpkgs.hostPlatform = isoSystem;}
              "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
              "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
              pkgsCfg
              inputs.disko.nixosModules.disko
              inputs.impermanence.nixosModules.impermanence
              inputs.sops-nix.nixosModules.sops
              ./host/iso-graphical.nix

              home-manager.nixosModules.home-manager
              {
                home-manager = {
                  inherit extraSpecialArgs;
                  useUserPackages = true;

                  sharedModules = [
                    pkgsCfg
                  ];

                  users = {
                    root = ./home/root.nix;
                    nixos = ./home/nixos-graphical.nix;
                  };
                };
              }
            ];
          };
        }
      );

    flatIsoCfgs = nixpkgs.lib.concatMapAttrs (name: systems:
      nixpkgs.lib.concatMapAttrs (system: v: {
        "${name}-${system}" = v;
      })
      systems)
    isoCfgs;
  in {
    overlays.default = overlay;
    formatter.${system} = nixpkgs.legacyPackages.${system}.alejandra;
    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

    nixosConfigurations =
      {
        hamilton = nixpkgs.lib.nixosSystem {
          inherit specialArgs;

          modules =
            commonModules
            ++ [
              inputs.disko.nixosModules.disko
              inputs.impermanence.nixosModules.impermanence

              ./host/hamilton.nix

              {
                home-manager = {
                  inherit extraSpecialArgs;
                  useUserPackages = true;

                  sharedModules = commonHmModules;

                  users = {
                    aftix = import ./home/aftix.nix;
                    root = import ./home/root.nix;
                  };
                };
              }
            ];
        };

        fermi = nixpkgs.lib.nixosSystem {
          inherit specialArgs;

          modules =
            commonModules
            ++ [
              inputs.srvos.nixosModules.common
              inputs.srvos.nixosModules.server
              inputs.srvos.nixosModules.mixins-nginx
              ./host/fermi.nix

              {
                home-manager = {
                  inherit extraSpecialArgs;
                  useUserPackages = true;

                  sharedModules = commonHmModules;

                  users = {
                    aftix = import ./home/aftix-minimal.nix;
                    root = import ./home/root.nix;
                  };
                };
              }
            ];
        };
      }
      // flatIsoCfgs;

    deploy.nodes.fermi = {
      hostname = "170.130.165.174";
      profiles.system = {
        user = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.fermi;
      };
    };

    nixosModules = {
      homeCommon = import ./home/common;
      impermanence = ./home/opt/impermanence.nix;

      development = import ./home/opt/development.nix;
      firefox = import ./home/opt/firefox.nix;
      helix = import ./home/opt/helix.nix;
      kitty = import ./home/opt/kitty.nix;
      neoutils = import ./home/opt/neoutils.nix;
      stylix = import ./home/opt/stylix.nix;
    };
  };
}
