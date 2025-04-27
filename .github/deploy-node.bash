#!/usr/bin/env bash

# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2

# Deploy configuration to node using nixos-rebuild-ng
# Configuration name should be in $1
# It is required to have the ATTIC_CACHE in environment and ~/.ssh/id_ed25519 populated

NODE="$1"

# Install nixos-rebuild-ng
nix profile install "nixpkgs#nixos-rebuild-ng"

# Add node fingerprint to known ssh hosts
ssh-keyscan -H "$HOSTNAME" > ~/.ssh/known_hosts

# Push new store paths to the binary cache
attic watch-store "ci:$ATTIC_CACHE" &
ATTIC_PID=$!
trap 'kill $ATTIC_PID' EXIT

# Deploy to node
just deploy "$NODE"

# Update $HOME/cfg repo with new changes, if it exists
ssh "${SSHUSER}@$HOSTNAME" 'sh -ls' <<< 'if [ -d "$HOME/cfg" ] && [ -d "$HOME/cfg/.git" ]; then cd "$HOME/cfg" ; git pull --rebase || true ; fi'
