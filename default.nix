let
  inputs = import ./flake-compat/inputs.nix;
  inherit (inputs.nixpkgs) lib;

  makeFlake = inps:
    lib.fix' (self:
      inps.self
      // {
        inputs = builtins.removeAttrs inps ["self"];
        overrideInputs = f: makeFlake (self.inputs.overrideInputs f);
      });
in
  makeFlake inputs
