{
  description = "Aftix's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    stablepkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = {
    nixpkgs,
    stablepkgs,
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
      ];
    };
  };
}
