{
  inputs ? import ./flake-compat/inputs.nix,
  overlay ? import ./overlay.nix inputs,
  pkgsCfg ? import ./nixpkgs-cfg.nix {inherit inputs overlay;},
  system ? builtins.currentSystem or "unknown-system",
  pkgs ? (import inputs.nixpkgs {
    inherit system;
    inherit (pkgsCfg.nixpkgs) config overlays;
  }),
  ...
}:
pkgs.aftixPkgs
// pkgs.aftixOverlayedPkgs
// {
  inherit
    (pkgs)
    matrix-synapse-unwrapped
    ;
}
