# Fetch the inputs from flake.nix, no processing is done
let
  inherit (builtins) readFile fromJSON fetchTarball elem;
  flakeInputs = (import ../flake.nix).inputs;
  lockFile = fromJSON (readFile ../flake.lock);

  # Fetchers
  fetchFromTarball = node:
    fetchTarball {
      url = node.locked.url;
      sha256 = node.locked.narHash;
    };
  fetchFromGithub = node:
    fetchTarball {
      url = "https://github.com/${node.locked.owner}/${node.locked.repo}/archive/${node.locked.rev}.tar.gz";
      sha256 = node.locked.narHash;
    };
  fetchNode = nodeName: let
    nodeTy = lockFile.nodes.${nodeName}.locked.type;
  in
    if nodeTy == "github"
    then fetchFromGithub lockFile.nodes.${nodeName}
    else if nodeTy == "tarball"
    then fetchFromTarball lockFile.nodes.${nodeName}
    else
      throw ''
        flake-compat/raw-inputs.nix: fetchNode: Unsupported node type ${nodeTy} for node ${nodeName}
      '';

  # bootstrap the nixpkgs inputs so there's access to the lib
  nixpkgs = fetchNode lockFile.nodes.root.inputs.nixpkgs;
  lib = import "${nixpkgs}/lib";

  inherit (lib) pipe filterAttrs mapAttrs;

  fetchedInputs = pipe flakeInputs [
    (filterAttrs (name: _: !elem name ["nixpkgs" "flake-compat"]))
    (mapAttrs (input: _: lockFile.nodes.root.inputs.${input}))
    (mapAttrs (name: nodeName: fetchNode nodeName))
  ];

  # Get the "systems" input from flake-utils
  nix-systems = let
    flakeUtilNode = lockFile.nodes.root.inputs.flake-utils;
    systemsNode = lockFile.nodes.${flakeUtilNode}.inputs.systems;
  in
    fetchNode systemsNode;

  # Get the "crane" input from attic
  crane = let
    atticNode = lockFile.nodes.root.inputs.attic;
  in
    fetchNode lockFile.nodes.${atticNode}.inputs.crane;

  # Get the "zig-deps-fod" input from nixos-cli
  zig-deps-fod = let
    nixos-cliNode = lockFile.nodes.root.inputs.nixos-cli;
  in
    fetchNode lockFile.nodes.${nixos-cliNode}.inputs.zig-deps-fod;
in
  fetchedInputs
  // {
    inherit nixpkgs nix-systems lib lockFile crane zig-deps-fod;
  }
