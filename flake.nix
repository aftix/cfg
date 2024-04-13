{
  description = "Aftix's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    stablepkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nur.url = "github:nix-community/NUR";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    impermanence.url = "github:nix-community/impermanence";

    aftix.url = "path:./home/aftix";
    aftix.inputs = {
      nixpkgs.follows = "nixpkgs";
      stablepkgs.follows = "stablepkgs";
      nur.follows = "nur";
    };
  };

  outputs = {
    nixpkgs,
    stablepkgs,
    nur,
    home-manager,
    impermanence,
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
    formatter."${system}" = upkgs.alejandra;
    nixosConfigurations.hamilton = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit upkgs;
        inherit spkgs;
        inherit nixpkgs;
        inherit stablepkgs;
      };
      modules = [
        impermanence.nixosModules.impermanence
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.root = import ./home/root/root.nix;
            users.aftix = import ./home/aftix/aftix.nix;
            extraSpecialArgs = {
              home-impermanence = impermanence.nixosModules.home-manager.impermanence;
              inherit upkgs;
              inherit spkgs;
            };
          };
        }
      ];
    };
    nixosModules = {
      kitty = import ./home/aftix/kitty.nix;
      vcs = import ./home/aftix/vcs.nix;
      helix = import ./home/aftix/helix.nix;
      firefox = import ./home/aftix/firefox.nix;
    };
  };
}
