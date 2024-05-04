_: {
  imports = [
    ./common

    ./opt/impermanence.nix
    ./opt/sops.nix

    ./opt/helix.nix
    ./opt/neoutils.nix
  ];

  home = {
    username = "root";
    homeDirectory = "/root";
    stateVersion = "23.11"; # DO NOT CHANGE
  };

  my.shell.elvish.enable = true;
}
