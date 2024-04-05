{ config, stableconfig, ... }: {
  pkgs = import (builtins.fetchGit {
    name = "nixos-unstable-2024-04-05";
    url = "https://github.com/nixos/nixpkgs";
    ref = "refs/heads/nixos-unstable";
    rev = "fd281bd6b7d3e32ddfa399853946f782553163b5";
  }) { inherit config; };
  stablepkgs = import (builtins.fetchGit {
    name = "nixos-23.11-2024-04-05";
    url = "https://github.com/nixos/nixpkgs";
    ref = "refs/heads/nixos-23.11";
    rev = "1487bdea619e4a7a53a4590c475deabb5a9d1bfb";
  }) { config = stableconfig; };
}
