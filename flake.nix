{
  description = "Aftix's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    stablepkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = {
    self,
    nixpkgs,
    stablepkgs,
    home-manager,
    impermanence,
    ...
  }: let
    system = "x86_64-linux";
    upkgs = import nixpkgs {
      inherit system;
      config.allowUnfreePredicate = pkg:
        builtins.elem (nixpkgs.lib.getName pkg) [
          "discord"
          "vault"
        ];
    };
    spkgs = import stablepkgs {inherit system;};
  in {
    nixosConfigurations.hamilton = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit upkgs;
        inherit spkgs;
      };
      modules = [
        impermanence.nixosModules.impermanence
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.aftix = import ./aftix.nix;
            extraSpecialArgs = {
              inherit upkgs;
              inherit spkgs;
            };
          };
        }
      ];
    };
  };
}
