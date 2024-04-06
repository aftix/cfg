# Module for dealing with NixOS
use path
use str
use re

# Rebuild nixos configuration and commit if succeeded
fn rebuild {
  tmp pwd = $E:HOME/src/cfg

  echo "Rebuilding NixOS..."
  sudo nixos-rebuild switch --flake . 2>&1 | tee nixos-switch.log | try {
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
