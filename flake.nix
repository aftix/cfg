{
  description = "Aftix's NixOS configuration";

  inputs = {
    lix = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    impermanence.url = "github:nix-community/impermanence";
    stylix.url = "github:danth/stylix";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "stablepkgs";
      };
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-cli.url = "github:water-sucks/nixos";

    coffeepaste = {
      url = "sourcehut:~mort/coffeepaste";
      flake = false;
    };
    barcodebuddy = {
      url = "github:Forceu/barcodebuddy/v1.8.1.7";
      flake = false;
    };
    carapace = {
      url = "github:carapace-sh/carapace-bin";
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

    attic.url = "github:zhaofengli/attic";
    helix.url = "github:helix-editor/helix";

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
    stablepkgs,
    nur,
    home-manager,
    deploy-rs,
    flake-utils,
    ...
  } @ inputs: let
    system = "x86_64-linux";

    substituters = [
      "https://nix-community.cachix.org"
      "https://helix.cachix.org"
      "https://cache.nixos.org"
      "https://cache.thalheim.io"
      "https://attic.aftix.xyz/cfg-actions"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc="
      "cfg-actions:R9aJEQdcJT8NrUh1yox2FgZfmzRrKi6MAobbfuRvv3g="
    ];

    overlay = import ./overlay.nix inputs;
    getModules = atPath: let
      getFilename = path: nixpkgs.lib.lists.last (nixpkgs.lib.strings.split "/" (builtins.toString path));
      mapAppendPath = path: f: p: v: f (nixpkgs.lib.path.append path p) v;
      recursiveGetModules = path: val:
        if val == "regular" && nixpkgs.lib.strings.hasSuffix ".nix" path
        then
          (
            let
              fName = getFilename path;
              name = nixpkgs.lib.strings.removeSuffix ".nix" fName;
            in {${name} = import path;}
          )
        else if val != "directory" || nixpkgs.lib.strings.hasPrefix "_" (getFilename path)
        then {}
        else
          (let
            subdir = builtins.readDir path;
          in
            if subdir ? "default.nix"
            then {${getFilename path} = import path;}
            else nixpkgs.lib.attrsets.concatMapAttrs (mapAppendPath path recursiveGetModules) subdir);
    in
      nixpkgs.lib.attrsets.concatMapAttrs (mapAppendPath atPath recursiveGetModules) (builtins.readDir atPath);

    pkgsCfg = {
      nixpkgs = {
        overlays = [
          nur.overlay
          inputs.helix.overlays.default
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
          permittedInsecurePackages = ["jitsi-meet-1.0.8043"];
        };
      };
    };

    spkgs = stablepkgs.legacyPackages.${system};

    depInject = {lib, ...}: {
      options.dep-inject = lib.mkOption {
        type = with lib.types; attrsOf unspecified;
        default = {};
      };

      config.dep-inject = {
        inherit spkgs inputs commonHmModules;
      };
    };

    depInjectHm = {lib, ...}: {
      options.dep-inject = lib.mkOption {
        type = with lib.types; attrsOf unspecified;
        default = {};
      };

      config.dep-inject = {
        inherit spkgs inputs;
      };
    };

    # Options that are for home-manager, but should be set on a per-host basis
    nixosHomeOptions = lib: {
      my.development.nixdConfig = lib.mkOption {
        default = {};
        description = "Configuration for the nixd LSP";
        type = with lib.types; attrsOf anything;
      };
    };

    # Nixos module for nixosHomeOptions
    # Allows nixos configurations to set options to propagate into each home-manager configuration
    nixosHomeModule = {lib, ...}: {options = nixosHomeOptions lib;};

    # Inject config from nixosHomeOptions into home-manager
    # Leaves a my.nixosCfg option set to the total system configuration, and
    # recursively picks out the options defined in nixosHomeOptions and injects them into the home-manager
    # configuration so those options in particular won't need a "my.nixosCfg" before the config path.
    # Downstream users should get this from the `extra` flake output and use it to generate a hm module
    # with their sysCfg injected. The nixos side is already in the default flake nixosModule, so nothing
    # extra is needed beyond that.
    hmInjectNixosHomeOptions = sysCfg: {lib, ...}: let
      homeOpts = nixosHomeOptions lib;
    in {
      imports = [{options = homeOpts;}];

      options.my.nixosCfg = lib.mkOption {
        description = "The NixOS configuration";
        readOnly = true;
        type = lib.types.raw;
      };

      config = let
        inherit (lib.attrsets) mapAttrsRecursiveCond hasAttrByPath getAttrFromPath;
      in
        lib.mkMerge [
          (
            mapAttrsRecursiveCond
            # Do not recurse into attrsets that are option definitions
            (attrs: !(attrs ? "_type" && attrs._type == "option"))
            (optPath: _:
              if hasAttrByPath optPath sysCfg
              then getAttrFromPath optPath sysCfg
              else null)
            homeOpts
          )
          {
            my.nixosCfg = sysCfg;
          }
        ];
    };

    commonModules = [
      pkgsCfg
      ({...}: {
        nixpkgs.overlays = [
          inputs.lix.overlays.default
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
      nixosHomeModule
      depInject
      {
        programs = {
          nix-index-database.comma.enable = true;
          command-not-found.enable = false;
        };
      }
      ({
        pkgs,
        lib,
        ...
      }: {
        nix = {
          package = lib.mkForce pkgs.nix;
          settings = {inherit substituters trusted-public-keys;};
        };
      })
    ];

    extraSpecialArgs = {
      inherit (inputs.sops-nix.homeManagerModules) sops;
      inherit (inputs.stylix.homeManagerModules) stylix;
      inherit (inputs.impermanence.nixosModules.home-manager) impermanence;
    };

    commonHmModules = [
      pkgsCfg
      inputs.nix-index-database.hmModules.nix-index
      {
        imports = [depInjectHm];
        programs = {
          nix-index-database.comma.enable = true;
          command-not-found.enable = false;
        };
      }
    ];

    genNixosSystem = {
      modules,
      users,
      extraAttrs ? {},
    }:
      nixpkgs.lib.nixosSystem ({
          modules =
            [
              self.nixosModules.default
            ]
            ++ modules
            ++ [
              ({config, ...}: let
                nixosHomeOptions = hmInjectNixosHomeOptions config;
              in {
                home-manager = {
                  useUserPackages = true;
                  inherit extraSpecialArgs users;

                  sharedModules = [
                    nixosHomeOptions
                    self.homemanagerModules.default
                  ];
                };
              })
            ];
        }
        // extraAttrs);
  in
    {
      overlays.default = overlay;

      nixosConfigurations = {
        hamilton = genNixosSystem {
          modules = [
            inputs.disko.nixosModules.disko
            inputs.impermanence.nixosModules.impermanence
            inputs.lanzaboote.nixosModules.lanzaboote
            ./host/hamilton.nix
          ];
          users = {
            aftix = import ./home/aftix.nix;
            root = import ./home/root.nix;
          };
        };

        fermi = genNixosSystem {
          modules = [
            inputs.srvos.nixosModules.server
            inputs.srvos.nixosModules.mixins-nginx

            ./host/fermi.nix
          ];
          users = {
            aftix = import ./home/aftix-minimal.nix;
            root = import ./home/root.nix;
          };
        };

        "iso-minimal" = genNixosSystem {
          modules = [
            {nixpkgs.hostPlatform = system;}
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
            inputs.disko.nixosModules.disko
            inputs.impermanence.nixosModules.impermanence
            ./host/iso-minimal.nix
          ];
          users = {
            root = ./home/root.nix;
            nixos = ./home/nixos.nix;
          };
        };

        "iso-graphical" = genNixosSystem {
          modules = [
            {nixpkgs.hostPlatform = system;}
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
            inputs.disko.nixosModules.disko
            inputs.impermanence.nixosModules.impermanence
            ./host/iso-graphical.nix
          ];
          users = {
            root = ./home/root.nix;
            nixos = ./home/nixos-graphical.nix;
          };
        };
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
          nix-substituters = {
            nix.settings = {inherit substituters trusted-public-keys;};
          };
        }
        // getModules ./host/opt;

      homemanagerModules =
        {
          default = {
            imports = commonHmModules ++ [./home/common];
          };
        }
        // getModules ./home/opt;

      extra = {
        # NOTE: you'll need to use these for some optional modules
        inherit extraSpecialArgs;

        inherit substituters trusted-public-keys nixosHomeOptions hmInjectNixosHomeOptions;
      };
    }
    // flake-utils.lib.eachDefaultSystem (sys: {
      formatter = let
        pkgs = nixpkgs.legacyPackages.${sys};
      in
        pkgs.alejandra or pkgs.nix-fmt;

      checks = nixpkgs.lib.attrsets.optionalAttrs (deploy-rs.lib ? "${sys}") (deploy-rs.lib.${sys}.deployChecks self.deploy);

      packages = let
        pkgs = nixpkgs.legacyPackages.${sys};
        appliedOverlay = self.overlays.default pkgs pkgs;
        helixOverlay = inputs.helix.overlays.default pkgs pkgs;
      in {
        inherit
          (appliedOverlay)
          carapace
          attic-client
          attic-server
          heisenbridge
          nginx_blocker
          youtube-operational-api
          nu_plugin_audio_hook
          nu_plugin_compress
          nu_plugin_dbus
          nu_plugin_desktop_notifications
          nu_plugin_dns
          nu_plugin_endecode
          nu_plugin_explore
          nu_plugin_port_scan
          nu_plugin_port_list
          nu_plugin_semver
          nu_plugin_skim
          nu_plugin_strutils
          ;

        inherit (helixOverlay) helix;
        lix = inputs.lix.packages.${sys}.default;
      };
    });
}
