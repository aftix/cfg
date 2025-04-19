{
  inputs ? (import ./.).inputs,
  pkgsCfg ? import ./nixpkgs-cfg.nix {inherit inputs;},
  system ? builtins.currentSystem or "unknown-system",
  pkgs ? (import inputs.nixpkgs {
    inherit system;
    inherit (pkgsCfg.nixpkgs) config overlays;
  }),
  ...
}:
pkgs.aftixPkgs
// pkgs.aftixOverlayedPkgs
