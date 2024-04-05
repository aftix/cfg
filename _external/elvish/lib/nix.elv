# Module for dealing with NixOS
use path
use str
use re

# Rebuild nixos configuration and commit if succeeded
fn rebuild {
  tmp pwd = $E:HOME/src/cfg

  echo "Rebuilding NixOS..."
    sudo nixos-rebuild switch 2>&1 | tee nixos-switch.log | try {
    grep --color 'error: '
  } catch { }

  if ?(grep --quiet 'error: ' nixos-switch.log) {
    fail "`nixos-rebuild switch` failed"
  }

  if (jj st | grep 'Working copy' | re:match '\(no description set\)' (slurp)) {
    var current = (nixos-rebuild list-generations | grep current)
    jj ci --message=$current
  } else {
    jj new
  }

  notify-send "NixOS Rebuild succeeded" --icon=software-update-available
}

# If there are changes in the configuration, nixos-rebuild switch and commit if succeeded
fn commit {
  tmp pwd = $E:HOME/src/cfg

  if (== (jj diff --no-pager --git --from @- | wc -l) 0) {
    echo "No changes detected, exiting"
    return
  }

  try {
    jj diff --from @-
  } catch { }

  printf "Continue with rebuild? (Y/n) "
  var response = (read-upto "\n" | str:trim (all) "\n" | str:to-lower (all))
  if (has-value [n no] $response) {
    echo "Exiting."
    return
  }

  rebuild
}

# Upgrade channels and rebuild
fn upgrade {
  tmp pwd = $E:HOME/src/cfg

  var unstable = [(str:split "\t" (git ls-remote 'https://github.com/nixos/nixpkgs' nixos-unstable | head -n1))]
  var stable = [(str:split "\t" (git ls-remote 'https://github.com/nixos/nixpkgs' nixos-23.11 | head -n1))]
  var ts = (date "+%Y-%m-%d")

  jj new >/dev/null 2>/dev/null

  echo '{ config, stableconfig, ... }: {
pkgs = import (builtins.fetchGit {
  name = "nixos-unstable-'$ts'";
  url = "https://github.com/nixos/nixpkgs";
  ref = "'$unstable[1]'";
  rev = "'$unstable[0]'";
  }) {};
stablepkgs = import (builtins.fetchGit {
  name = "nixos-23.11-'$ts'";
  url = "https://github.com/nixos/nixpkgs";
  ref = "'$stable[1]'";
  rev = "'$stable[0]'";
}) {};
}' > channels.nix

  if (== (jj diff --no-pager --git --from @- | wc -l) 0) {
    echo "No updates detected, exiting"
    jj edit @- >/dev/null 2>&1
    return
  }

  rebuild
}
