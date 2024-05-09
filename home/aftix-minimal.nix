_: {
  imports = [
    ./common

    ./opt/sops.nix

    ./opt/development.nix
    ./opt/helix.nix
    ./opt/neoutils.nix
  ];

  home = {
    username = "aftix";
    homeDirectory = "/home/aftix";
    stateVersion = "23.11"; # DO NOT CHANGE
  };

  my = {
    shell.elvish.enable = false;
    docs = {
      enable = true;
      prefix = "nixos";
    };

    development = {
      gh = false;
      rust = false;
      typescript = false;
    };
  };
}
