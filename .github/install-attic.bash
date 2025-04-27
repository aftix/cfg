#!/usr/bin/env bash

# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2

# Install attic-client into the nix profile
# and setup the default cache
echo ATTIC_CACHE="$ATTIC_CACHE" | tee -a "$GITHUB_ENV"
nix profile install '.#attic-client'
attic login --set-default ci "$ATTIC_SERVER" "$ATTIC_TOKEN"
attic use "$ATTIC_CACHE"
