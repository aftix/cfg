{inputs ? import ./inputs.nix, ...}: {
  inherit (inputs.sops-nix.homeManagerModules) sops;
  inherit (inputs.stylix.homeManagerModules) stylix;
}
