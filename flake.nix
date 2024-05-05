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

    impermanence.url = "github:nix-community/impermanence";
    stylix.url = "github:aftix/stylix";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = {
    nixpkgs,
    stablepkgs,
    nur,
    home-manager,
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
    pkgs = import nixpkgs {inherit system;};
    spkgs = import stablepkgs {inherit system;};

    specialArgs = {inherit spkgs inputs;};
    extraSpecialArgs =
      specialArgs
      // {
        home-impermanence = inputs.impermanence.nixosModules.home-manager.impermanence;
        inherit (inputs.stylix.homeManagerModules) stylix;
        sops-nix = inputs.sops-nix.homeManagerModules.sops;
      };

    hostCfgs = {
      hamilton = ./host/hamilton.nix;
    };
    homeCfgs = {
      aftix = ./home/aftix.nix;
      root = ./home/root.nix;
    };
  in {
    formatter.${system} = pkgs.alejandra;

    nixosConfigurations =
      builtins.mapAttrs (
        host: path:
          nixpkgs.lib.nixosSystem {
            inherit system specialArgs;

            modules = [
              pkgsCfg
              inputs.disko.nixosModules.disko
              inputs.impermanence.nixosModules.impermanence
              inputs.sops-nix.nixosModules.sops
              path

              home-manager.nixosModules.home-manager
              {
                home-manager = {
                  inherit extraSpecialArgs;
                  useUserPackages = true;

                  sharedModules = [
                    pkgsCfg
                  ];

                  users = builtins.mapAttrs (_: import) homeCfgs;
                };
              }
            ];
          }
      )
      hostCfgs;

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
