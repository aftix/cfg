{
  description = "Aftix's NixOS configuration";

  inputs = {
    lix = {
      url = "https://git.lix.systems/lix-project/lix/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/main.tar.gz";
      inputs = {
        lix.follows = "lix";
        nixpkgs.follows = "nixpkgs";
      };
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    srvos = {
      url = "github:numtide/srvos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    preservation.url = "github:willibutz/preservation";
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-cli.url = "github:water-sucks/nixos";

    carapace = {
      url = "github:carapace-sh/carapace-bin";
      flake = false;
    };

    attic.url = "github:zhaofengli/attic";

    hostsBlacklist = {
      url = "github:Ultimate-Hosts-Blacklist/Ultimate.Hosts.Blacklist";
      flake = false;
    };
    nginxBlacklist = {
      url = "github:mitchellkrogza/nginx-ultimate-bad-bot-blocker";
      flake = false;
    };

    hyprland = {
      url = "github:hyprwm/hyprland";
      flake = false; # Just want the wallpaper image
    };
  };

  outputs = {
    self,
    nixpkgs,
    deploy-rs,
    ...
  } @ inputs: let
    myLib = import ./lib.nix inputs;
    nixSettings = import ./nix-settings.nix;
    overlay = import ./overlay.nix inputs;
    pkgsCfg = import ./nixpkgs-cfg.nix {inherit inputs myLib overlay;};
    extraSpecialArgs = import ./extraSpecialArgs.nix {inherit inputs;};
  in {
    overlays.default = overlay;
    nixosConfigurations = import ./nixosConfigurations.nix {
      inherit inputs myLib extraSpecialArgs;
    };
    deploy = import ./deploy.nix {inherit inputs;};
    nixosModules = import ./nixosModules.nix {
      inherit inputs overlay myLib pkgsCfg;
    };
    homemanagerModules = import ./homemanagerModules.nix {
      inherit inputs overlay myLib pkgsCfg;
    };
    extra = {
      # NOTE: you'll need to use these for some optional modules
      inherit extraSpecialArgs myLib;

      inherit
        (nixSettings)
        substituters
        trusted-public-keys
        extra-experimental-features
        ;
    };

    formatter = myLib.forEachSystem (sys: let
      pkgs = inputs.nixpkgs.legacyPackages.${sys};
    in
      pkgs.alejandra or pkgs.nix-fmt);

    checks = myLib.forEachSystem (sys: nixpkgs.lib.attrsets.optionalAttrs (deploy-rs.lib ? "${sys}") (deploy-rs.lib.${sys}.deployChecks self.deploy));

    legacyPackages = myLib.forEachSystem (system:
      import ./packages.nix {
        inherit inputs myLib overlay pkgsCfg system;
      });
  };
}
