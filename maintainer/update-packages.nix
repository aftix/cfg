# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  inputs ? import ../inputs.nix,
  myLib ? import ../lib.nix {inherit inputs;},
  pkgsCfg ? import ../nixpkgs-cfg.nix {inherit inputs myLib;},
  system ? builtins.currentSystem or "unknown-system",
  pkgs ? (import inputs.nixpkgs {
    inherit system;
    inherit (pkgsCfg.nixpkgs) config overlays;
  }),
  ...
}: let
  inherit (pkgs) lib;
  # Get repo packages
  packages = import ../packages.nix {inherit inputs myLib pkgsCfg system pkgs;};
  # Get a nested attrset of the attrpaths,
  # or null if the package doesn't have an update script
  drvToAttrpathCond = path: val:
    if lib.isDerivation val && lib.hasAttrByPath ["passthru" "updateScript"] val
    then lib.concatStringsSep "." path
    else null;
  updatablePaths = lib.mapAttrsRecursiveCond (lib.hasAttr "recurseForDerivations") drvToAttrpathCond packages;

  # Create a list of all attrpaths that can be updated
  attrsToList = lib.mapAttrsToList (_: val:
    if lib.isAttrs val
    then lib.flatten (attrsToList val)
    else val);
  updatable = lib.pipe updatablePaths [
    attrsToList
    lib.flatten
    (lib.filter (v: v != null))
  ];

  attrPathToCommand = lib.flip lib.pipe [
    (lib.splitString ".")
    (x: x ++ ["passthru" "updateScript"])
    (lib.flip lib.getAttrFromPath packages)
    (
      x: let
        cmd = lib.head x;
        args = lib.tail x;
      in
        if lib.strings.hasSuffix "nix-update" cmd
        then [cmd "-f" "packages.nix"] ++ args # Add -f packages.nix as the first two arguments to the nix-update command
        else x # Do not modify update scripts that are not nix-update
    )
    (lib.concatStringsSep " ")
    lib.escapeShellArg
  ];

  scriptMap =
    lib.map
    (attrpath: "[\"${attrpath}\"]=${attrPathToCommand attrpath}")
    updatable;

  systemdInhibit = action:
    lib.optionalString pkgs.stdenv.hostPlatform.isLinux
    /*
    bash
    */
    ''systemd-inhibit --mode=block --why="${action} package $name" --who="$(pwd)/maintainer/update-packages.nix"'';
in
  pkgs.writeShellApplication {
    name = "update-package";
    runtimeInputs =
      [pkgs.jujutsu pkgs.nix-output-monitor pkgs.nix-update pkgs.coreutils-full pkgs.lixPackageSets.git.lix]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [pkgs.systemd];
    text = ''
      declare -a validPaths=(${lib.escapeShellArgs updatable})
      declare -A updateScripts=(${lib.concatStringsSep " " scriptMap})

      if [[ "$(jj log -r @ --no-graph -T "if(self.empty(), 1, 0)")" != 1 ]]; then
          echo 'Error: running update-package on non-empty commit' >&2
          exit 1
      fi

      if ! [[ -f packages.nix ]]; then
        echo 'Error: packages.nix not found' >&2
        exit 1
      fi

      # Turn any store path for nix-update into a plain call to the one in PATH
      replaceUpdateScript() {
        local path="$1"

        if [[ "$path" =~ ^/nix/store/[[:alnum:]]+-nix-update-[[:digit:].]+/bin/nix-update[[:space:]]*$ ]]; then
          echo "nix-update"
        else
          printf '%s\n' "$path"
        fi
      }

      # Fetch any update scripts needed
      fetchUpdateScript () {
        local path="$1"

        [[ "$path" =~ ^/nix/store ]] || return 0
        [[ -f "$path" ]] && return 0
        nix --extra-experimental-features "nix-command" copy --from "https://cache.nixos.org" "$path"
      }

      updatePackage() {
        local name="$1"

        if [[ ! " ''${validPaths[*]} " =~ [[:space:]]''${name}[[:space:]] ]]; then
          echo "Error: Package $name is not an updatable package (or it does not exist)" >&2
          return 1
        fi

        # Turn arguments into an array for explicit word splitting
        read -ra updateArgs <<<"''${updateScripts["$name"]}"
        updateArgs[0]="$(replaceUpdateScript "''${updateArgs[0]}")"
        fetchUpdateScript "''${updateArgs[0]}"

        ${systemdInhibit "Updating"} "''${updateArgs[@]}" "$name"
        # shellcheck disable=SC2181
        # putting command directly in the if doesn't really word with nix generation
        if [[ "$?" != 0 ]]; then
          echo "Error: Failed to update package $name" >&2
          return 1
        fi

        if [[ "$(jj log -r @ --no-graph -T "if(self.empty(), 1, 0)")" = 1 ]]; then
            echo "No updates found for $name"
            return 1
        fi

        echo "Checking if package $name builds"
        ${systemdInhibit "Building"} nom build -f packages.nix "$name" --no-link --print-out-paths
        # shellcheck disable=SC2181
        # putting command directly in the if doesn't really word with nix generation
        if [[ "$?" = 0 ]]; then
          echo "Package $name built"
          jj ci -m "chore(legacyPackages.$name): update package using passthru.updateScript" --quiet
          return 0
        else
          echo "Package $name not built, abandoning change" >&2
          jj abandon --quiet
          return 1
        fi
      }

      toUpdate=()
      if [[ $# -gt 0 ]]; then
        toUpdate=("$@")
      else
        toUpdate=("''${validPaths[@]}")
      fi

      counter=0
      for pkg in "''${toUpdate[@]}"; do
        if updatePackage "$pkg" ; then
          ((counter++)) || :
        fi
      done

      echo "Updated $counter packages."
    '';
  }
