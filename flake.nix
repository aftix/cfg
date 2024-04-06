{
  description = "Aftix's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    stablepkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    impermanence.url = "github:nix-community/impermanence";

    aftix.url = "path:./home/aftix";
    aftix.inputs.nixpkgs.follows = "nixpkgs";
    aftix.inputs.stablepkgs.follows = "stablepkgs";
  };

  outputs = {
    nixpkgs,
    stablepkgs,
    home-manager,
    impermanence,
    aftix,
    ...
  }: let
    system = "x86_64-linux";
    lib = nixpkgs.lib // home-manager.lib;
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
    formatter = upkgs.nixfmt;
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
  };
}
