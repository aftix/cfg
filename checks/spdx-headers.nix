# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  runCommand,
  lib,
  stdenv,
  findutils,
  util-linux,
}: let
  workspace = lib.fileset.toSource {
    fileset = lib.fileset.intersection ../. (lib.fileset.gitTracked ../.);
    root = ../.;
  };

  prune = [
    ".reuse"
    "LICENSES"
    "secrets"
    "npins"
    ".github"
  ];

  excluded = [
    "npins"
    "LICENSE"
    "LICENSES"
    "\\.gitignore$"
    "\\.reuse"
    "id_[a-zA-Z0-9]+(\\.pub)?$"
    "flake\\.lock"
    "\\.sops\\.yaml"
    "\\.(jpg|jpeg|png|gif)$"
    "\\.(patch|lock(\\.hcl)?|json)$"
    (lib.escapeRegex "nixosModules/hostBlacklist/personal-blacklist")
  ];

  pruneStr = lib.optionalString (prune != []) (lib.concatStringsSep " -o " (
    lib.map (dir: "-path \"$src/${dir}\" -prune") prune
  ));

  excludeRegex = lib.optionalString ((prune ++ excluded) != []) (lib.concatStringsSep "|" (
    prune ++ excluded
  ));
in
  lib.recursiveUpdate (runCommand "spdx-headers" {
      src = workspace;
      nativeBuildInputs = [findutils util-linux];
    } ''
      local count
      COUNTFILE="$(mktemp)"
      echo 0 > "$COUNTFILE"

      find "$src" \
        ${pruneStr} \
        -o -type f \
        -exec bash -c '[[ -f "$1" ]] && echo "$1" || :' empty '{}' ';' \
        | sed "s@$src/@@" \
        | grep -Ev ${lib.escapeShellArg excludeRegex} \
        | while read -r file ; do
          if ! head -n1 "$src/$file" | grep '^# SPDX-FileType: SOURCE$' &>/dev/null ; then
            echo "File $file is missing SPDX header"
            count="$(cat "$COUNTFILE")"
            echo "$(( count + 1 ))" > "$COUNTFILE"
          fi
        done


        count="$(cat "$COUNTFILE")"
        if [[ "$count" -gt 1 ]]; then
          echo "$count files missing SPDX header."
          exit "$count"
        elif [[ "$count" -gt 0 ]]; then
          echo "1 file missing SPDX header."
          exit 1
        fi

        touch "$out"
    '') {
    meta = {
      description = "Check that source files contain SPDX headers";
      hydraPlatforms = [stdenv.hostPlatform.system]; # Only check on the main platform
    };
  }
