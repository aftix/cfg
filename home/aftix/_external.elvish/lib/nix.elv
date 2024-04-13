# Module for dealing with NixOS
use path
use str
use re

# Rebuild nixos configuration and commit if succeeded
fn rebuild {
  tmp pwd = $E:HOME/src/cfg

  echo "Rebuilding NixOS..."
  nix flake lock --update-input aftix
  try {
    sudo nixos-rebuild switch --flake . 2>&1 | tee nixos-switch.log | grep --color -P '(?<!warning:)error: '
  } catch { }

  if ?(grep --quiet -P '(?<!warning:)error: ' nixos-switch.log) {
    notify-send --urgency critical --icon=software-update-available --app-name nixos "NixOS Rebuild failed"
    fail "`nixos-rebuild switch` failed"
  }

  if (== (jj diff --no-pager --git --from @- | wc -l) 0) {
    notify-send --app-name nixos "NixOS Rebuild succeeded" --icon=software-update-available
    return
  }

  if (jj st | grep 'Working copy' | re:match '\(no description set\)' (slurp)) {
    var current = (nixos-rebuild list-generations | grep current)
    jj ci --message=$current
  } else {
    jj new
  }

  notify-send --app-name nixos "NixOS Rebuild succeeded" --icon=software-update-available
}

# Rebuild home-manager configuration and commit if succeeded
fn rebuild_home {
  tmp pwd = $E:HOME/src/cfg

  echo "Rebuilding Home..."
  try {
    home-manager switch --flake ./home/aftix -b backup 2>&1 | tee home-manager-switch.log | grep --color -P '(?<!warning:)error: '
  } catch { }

  if ?(grep --quiet -P '(?<!warning:)error: ' home-manager-switch.log) {
    notify-send --urgency critical --app-name "Home Manager" "Home manager Rebuild failed" --icon=software-update-available
    fail "`home-manager switch` failed"
  }

  # Update the overall system configuration flake with the new aftix input
  nix flake lock --update-input aftix

  if (== (jj diff --no-pager --git --from @- | wc -l) 0) {
    notify-send --app-name "Home Manager" "Home manager rebuild secceeded" --icon=software-update-available
    return
  }

  if (jj st | grep 'Working copy' | re:match '\(no description set\)' (slurp)) {
    var current = (home-manager generations | head -n1)
    jj ci --message=$current
  } else {
    jj new
  }

  notify-send --app-name "Home Manager" "Home manager rebuild secceeded" --icon=software-update-available
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
