#!/usr/bin/env bash
# Install attic-client into the nix profile
# and setup the default cache
echo ATTIC_CACHE="$ATTIC_CACHE" | tee -a "$GITHUB_ENV"
nix profile install '.#attic-client'
attic login --set-default ci "$ATTIC_SERVER" "$ATTIC_TOKEN"
attic use "$ATTIC_CACHE"
