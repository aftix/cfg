{
  description = "Aftix's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    stablepkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nur.url = "github:nix-community/NUR";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";
    stylix.url = "github:aftix/stylix";
    sops-nix.url = "github:Mic92/sops-nix";

    hyprland.url = "github:hyprwm/Hyprland/v0.40.0?submodules=1";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    waybar = {
      url = "github:Alexays/Waybar";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    stablepkgs,
    nur,
    home-manager,
    flake-utils,
    ...
  } @ inputs: let
    system = "x86_64-linux";

    overlay = _: prev: {
      coreutils-full = prev.uutils-coreutils-noprefix;

      stty = prev.writeScriptBin "stty" (let
        pkg =
          if prev.lib.strings.hasSuffix "-linux" prev.system
          then prev.busybox
          else prev.coreutils;
      in ''
        #!${prev.stdenv.shell}
        ${pkg}/bin/stty $@
      '');
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
            "vault"
            "nordvpn"
            "pay-by-privacy"
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

    mkHostCfg = name: users: let
      inherit (nixpkgs) lib;
      workDir = ./.;
    in
      lib.nixosSystem {
        inherit specialArgs;

        modules = [
          pkgsCfg

          inputs.disko.nixosModules.disko
          inputs.impermanence.nixosModules.impermanence
          inputs.sops-nix.nixosModules.sops
          inputs.nix-index-database.nixosModules.nix-index

          "${workDir}/host/${name}.nix"

          home-manager.nixosModules.home-manager
          {
            home-manager = {
              inherit extraSpecialArgs;
              useUserPackages = true;

              sharedModules = [
                pkgsCfg
                inputs.nix-index-database.hmModules.nix-index
              ];

              users = lib.mergeAttrsList (builtins.map (user: {${user} = import "${workDir}/home/${user}.nix";}) users);
            };
          }
        ];
      };
  in {
    inherit overlay;

    formatter.${system} = nixpkgs.legacyPackages.${system}.alejandra;

    nixosConfigurations = {
      hamilton = mkHostCfg "hamilton" ["root" "aftix"];

      "iso-minimal-${system}" = nixpkgs.lib.nixosSystem {
        inherit specialArgs;

        modules = [
          {nixpkgs.hostPlatform = system;}
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
          pkgsCfg
          inputs.disko.nixosModules.disko
          inputs.impermanence.nixosModules.impermanence
          inputs.sops-nix.nixosModules.sops
          ./host/iso-minimal.nix

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
                nixos = ./home/nixos.nix;
              };
            };
          }
        ];
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
