{inputs, ...}: {
  entrypoint = ./configuration.nix;
  users = {
    nixos = import ../../homeConfigurations/nixos-graphical.nix;
    root = import ../../homeConfigurations/root.nix;
  };
  extraMods = [
    {nixpkgs.hostPlatform = "x86_64-linux";}
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
    inputs.disko.nixosModules.disko
    ./configuration.nix
  ];
}
