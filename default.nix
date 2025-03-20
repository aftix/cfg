let
  inputs = import ./flake-compat/inputs.nix;
in
  inputs.self.lib.makeFlake inputs
