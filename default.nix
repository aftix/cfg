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
  myLib = import ./lib.nix outputs.inputs;

  # Override default flake resolver for some inputs
  resolvers = import ./resolvers.nix {inherit lib myLib;};

  outputs = let
    schema = nixputs.schemas.flake.overrideResolvers resolvers;
  in
    schema
    // {
      inputs =
        schema.inputs
        // {
          self = schema;
        };
    };
in
  outputs
