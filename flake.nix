{
  description = "Aftix's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    stablepkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nur.url = "github:nix-community/NUR";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";

    impermanence.url = "github:nix-community/impermanence";
    stylix.url = "github:aftix/stylix";
    sops-nix.url = "github:Mic92/sops-nix";
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

    pkgsCfg = {
      nixpkgs = {
        overlays = [nur.overlay];
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

    specialArgs = {inherit spkgs inputs;};
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
          "${workDir}/host/${name}.nix"

          home-manager.nixosModules.home-manager
          {
            home-manager = {
              inherit extraSpecialArgs;
              useUserPackages = true;

              sharedModules = [
                pkgsCfg
              ];

              users = lib.mergeAttrsList (builtins.map (user: {${user} = import "${workDir}/home/${user}.nix";}) users);
            };
          }
        ];
      };
  in {
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
