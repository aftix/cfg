{inputs ? import ./flake-compat/inputs.nix, ...}: {
  inherit (inputs.sops-nix.homeManagerModules) sops;
  inherit (inputs.stylix.homeManagerModules) stylix;
}
