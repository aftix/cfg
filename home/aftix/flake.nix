{
  description = "Afitx's home manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    stablepkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nur.url = "github:nix-community/NUR";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
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
    lib = nixpkgs.lib // home-manager.lib;
    upkgs = import nixpkgs {
      inherit system;
      overlays = [nur.overlay];
      config.allowUnfreePredicate = pkg:
        builtins.elem (nixpkgs.lib.getName pkg) ["discord" "vault" "pay-by-privacy"];
    };
    spkgs = import stablepkgs {inherit system;};
    extraSpecialArgs = {
      inherit upkgs;
      inherit spkgs;
      home-impermanence = impermanence.nixosModules.home-manager.impermanence;
    };
  in {
    formatter."${system}" = upkgs.nixfmt;
    homeConfigurations.aftix = lib.homeManagerConfiguration {
      pkgs = upkgs;
      modules = [./aftix.nix];
      inherit extraSpecialArgs;
    };
  };
}
