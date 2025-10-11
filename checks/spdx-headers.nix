# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  runCommand,
  lib,
  hostPlatform,
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
  ];

  excluded = [
    "LICENSE"
    "LICENSES"
    ".gitignore"
    ".reuse"
    "flake.lock"
    ".github/clean-space.bash"
    ".github/deploy-node.bash"
    ".github/install-attic.bash"
    ".sops.yaml"
    "extraHomemanagerModules/wallpaper.jpg"
    "nixosConfigurations/fermi/www/attic_client_user_agent.patch"
    "nixosModules/hostBlacklist/personal-blacklist"
    "packages/coffeepaste/change-url-replace.patch"
    "packages/youtube-operational-api/composer.json"
    "packages/youtube-operational-api/composer.lock"
    "packages/youtube-operational-api/composer.patch"
  ];

  pruneStr = lib.optionalString (prune != []) (lib.concatStringsSep " -o " (
    lib.map (dir: "-path \"$src/${dir}\" -prune") prune
  ));

  excludeRegex = lib.optionalString ((prune ++ excluded) != []) (lib.concatStringsSep "|" (
    lib.map lib.escapeRegex (prune ++ excluded)
  ));
in
  lib.recursiveUpdate (runCommand "spdx-headers" {
      src = workspace;
      nativeBuildInputs = [findutils util-linux];
    } ''
      CODEFILE="$(mktemp)"
      echo 0 > "$CODEFILE"

      find "$src" \
        ${pruneStr} \
        -o -type f \
        -exec bash -c '[[ -f "$1" ]] && echo "$1" || :' empty '{}' ';' \
        | sed "s@$src/@@" \
        | grep -Ev ${lib.escapeShellArg "^(${excludeRegex})$"} \
        | while read -r file ; do
          if ! head -n1 "$src/$file" | grep '^# SPDX-FileType: SOURCE$' &>/dev/null ; then
            echo "File $file is missing SPDX header"
            echo 1 > "$CODEFILE"
          fi
        done

        EXITCODE="$(cat $CODEFILE)"
        if ! [[ "$EXITCODE" = "0" ]]; then
          exit "$EXITCODE"
        fi

        touch "$out"
    '') {
    meta = {
      description = "Check that source files contain SPDX headers";
      hydraPlatforms = [hostPlatform.system]; # Only check on the main platform
    };
  }
