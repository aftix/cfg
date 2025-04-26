let
  # Bootstrap the nixputs input
  lockFile = builtins.fromJSON (builtins.readFile ./flake.lock);
  root = lockFile.nodes.${lockFile.root};

  nixputsSource = let
    inherit
      (lockFile.nodes.${root.inputs.nixputs}.locked)
      url
      narHash
      ;
  in
    builtins.fetchTarball {
      inherit url;
      sha256 = narHash;
    };
  nixputs = import nixputsSource {
    src = ./.;
    system = null;
  };

  inherit (nixputs) lib;

  # bootstrap ./lib
  myLib = import ./lib.nix inputs;

  # Override default flake resolver for some inputs
  resolvers = import ./resolvers.nix {inherit lib myLib;};

  inputs = (nixputs.inputs.overrideResolvers resolvers).overrideInputs {
    inherit nixputs;
  };
in
  inputs
