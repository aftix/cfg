let
  inputs = import ./inputs.nix;
  inherit (inputs) resolvers;
in
  inputs.nixputs.schemas.flake.overrideResolvers resolvers
