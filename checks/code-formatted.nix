# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  runCommand,
  lib,
  hostPlatform,
  alejandra,
}:
lib.recursiveUpdate (runCommand "code-formatted" {
    src = ../.;
  } ''
    ${lib.getExe alejandra} -c "$src"
    touch "$out"
  '') {
  meta = {
    description = "Check that source is formatted with alejandra";
    hydraPlatforms = [hostPlatform.system]; # Only check on the main platform
  };
}
