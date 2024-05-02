{
  config,
  mylib-builder,
  ...
}: let
  mylib = mylib-builder config;
in {
  _module.args.mylib = mylib;

  imports = [
    ./common

    ./opt/impermanence.nix
    ./opt/sops.nix

    ./opt/elvish.nix
    ./opt/helix.nix
    ./opt/neoutils.nix
  ];

  home = {
    username = "root";
    homeDirectory = "/root";
    stateVersion = "23.11"; # DO NOT CHANGE
  };
}
