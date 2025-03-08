# Fetch the inputs from flake.nix, no processing is done
let
  inherit (builtins) readFile fromJSON fetchTarball fetchGit elem;
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
  fetchFromGit = node:
    fetchGit {
      inherit (node.locked) url rev ref;
    };
  fetchNode = nodeName: let
    nodeTy = lockFile.nodes.${nodeName}.locked.type;
  in
    if nodeTy == "github"
    then fetchFromGithub lockFile.nodes.${nodeName}
    else if nodeTy == "tarball"
    then fetchFromTarball lockFile.nodes.${nodeName}
    else if nodeTy == "git"
    then let
      fetched = fetchFromGit lockFile.nodes.${nodeName};
    in
      assert fetched.narHash == lockFile.nodes.${nodeName}.locked.narHash; fetched
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

  # Get the "crane" input from attic
  crane = let
    atticNode = lockFile.nodes.root.inputs.attic;
  in
    fetchNode lockFile.nodes.${atticNode}.inputs.crane;
in
  fetchedInputs
  // {
    inherit nixpkgs lib lockFile crane;
  }
