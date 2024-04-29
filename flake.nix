{
  description = "Aftix's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    stablepkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nur.url = "github:nix-community/NUR";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    impermanence.url = "github:nix-community/impermanence";

    stylix.url = "github:danth/stylix";

    aftix.url = "path:./home/aftix";
    aftix.inputs = {
      nixpkgs.follows = "nixpkgs";
      stablepkgs.follows = "stablepkgs";
      nur.follows = "nur";
      stylix.follows = "stylix";
    };
  };

  outputs = {
    nixpkgs,
    stablepkgs,
    nur,
    home-manager,
    impermanence,
    stylix,
    ...
  }: let
    system = "x86_64-linux";
    upkgs = import nixpkgs {
      inherit system;
      overlays = [nur.overlay];
      config.allowUnfreePredicate = pkg:
        builtins.elem (nixpkgs.lib.getName pkg) [
          "discord"
          "vault"
          "nordvpn"
          "pay-by-privacy"
        ];
    };
    spkgs = import stablepkgs {inherit system;};
  in {
    formatter.${system} = upkgs.alejandra;
    nixosConfigurations.hamilton = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit upkgs spkgs nixpkgs stablepkgs home-manager;
      };
      modules = [
        impermanence.nixosModules.impermanence
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = {
              home-impermanence = impermanence.nixosModules.home-manager.impermanence;
              stylix = stylix.homeManagerModules.stylix;
              inherit upkgs spkgs nixpkgs stablepkgs;
            };

            users.root = import ./home/root/root.nix;
            users.aftix = import ./home/aftix/aftix.nix;
          };
        }
      ];
    };
    nixosModules = {
      kitty = import ./home/aftix/kitty.nix;
      vcs = import ./home/aftix/vcs.nix;
      helix = import ./home/aftix/helix.nix;
      firefox = import ./home/aftix/firefox.nix;
      myopts = import ./home/aftix/myoptions.nix;
      mylib = import ./home/aftix/mylib.nix;
      stylix = import ./home/aftix/stylix.nix;
      documentation = import ./home/aftix/documentation.nix;
    };
  };
}
