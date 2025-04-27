# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  runCommand,
  lib,
  hostPlatform,
  reuse,
}:
lib.recursiveUpdate (runCommand "reuse-lint" {
    src = ../.;
  } ''
    pushd "$src" &>/dev/null
    ${lib.getExe reuse} lint
    popd &>/dev/null

    touch "$out"
  '') {
  meta = {
    description = "Check that licensing information passes REUSE's standards";
    hydraPlatforms = [hostPlatform.system]; # Only check on the main platform
  };
}
