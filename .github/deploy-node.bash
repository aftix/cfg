#!/usr/bin/env bash
# Deploy configuration to node using deploy-rs
# Configuration name should be in $1
# Hostname should be in $2
# If $3 is passed, it is the ssh user. Otherwise, ssh user is aftix
# It is required to have the ATTIC_CACHE in environment and ~/.ssh/id_ed25519 populated

NODE="$1"
HOSTNAME="$2"
SSHUSER="${3:-aftix}"

# Add node fingerprint to known ssh hosts
ssh-keyscan -H "$HOSTNAME" > ~/.ssh/known_hosts

# Push new store paths to the binary cache
attic watch-store "ci:$ATTIC_CACHE" &
ATTIC_PID=$!
trap 'kill $ATTIC_PID' EXIT

# Deploy to node
nix run 'github:serokell/deploy-rs' ".#$NODE" -- --ssh-user "$SSHUSER" -- --impure

# Update $HOME/cfg repo with new changes, if it exists
ssh "${SSHUSER}@$HOSTNAME" 'sh -ls' <<< 'if [ -d "$HOME/cfg" ] && [ -d "$HOME/cfg/.git" ]; then cd "$HOME/cfg" ; git pull --rebase || true ; fi'
