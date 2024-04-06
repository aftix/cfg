{
  description = "Afitx's home manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    stablepkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = {
    nixpkgs,
    stablepkgs,
    home-manager,
    impermanence,
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
    extraSpecialArgs = {
      inherit upkgs;
      inherit spkgs;
      home-impermanence = impermanence.nixosModules.home-manager.impermanence;
    };
  in {
    formatter = upkgs.nixfmt;
    homeConfigurations.aftix = lib.homeManagerConfiguration {
      pkgs = upkgs;
      modules = [./aftix.nix];
      inherit extraSpecialArgs;
    };
  };
}
