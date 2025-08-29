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
    lib.tail # remove the script path, only keep args
    (x: ["-f" "packages.nix"] ++ x)
    (lib.concatStringsSep " ")
    lib.escapeShellArg
  ];

  scriptMap =
    lib.map
    (attrpath: "[\"${attrpath}\"]=${attrPathToCommand attrpath}")
    updatable;

  systemdInhibit = action:
    lib.optionalString pkgs.hostPlatform.isLinux
    /*
    bash
    */
    ''systemd-inhibit --mode=block --why="${action} package $name" --who="$(pwd)/maintainer/update-packages.nix"'';
in
  pkgs.writeShellApplication {
    name = "update-package";
    runtimeInputs = [pkgs.jujutsu pkgs.nix-output-monitor pkgs.nix-update] ++ lib.optionals pkgs.hostPlatform.isLinux [pkgs.systemd];
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

      updatePackage() {
        local name="$1"

        if [[ ! " ''${validPaths[*]} " =~ [[:space:]]''${name}[[:space:]] ]]; then
          echo "Error: Package $name is not an updatable package (or it does not exist)" >&2
          return 1
        fi

        # Turn arguments into an array for explicit word splitting
        read -ra updateArgs <<<"''${updateScripts["$name"]}"
        ${systemdInhibit "Updating"} nix-update "''${updateArgs[@]}" "$name"
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
