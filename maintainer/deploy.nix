# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  inputs ? import ../inputs.nix,
  myLib ? import ../lib.nix {inherit inputs;},
  pkgsCfg ? import ../nixpkgs-cfg.nix {inherit inputs myLib;},
  system ? builtins.currentSystem or "unknown-system",
  extraSpecialArgs ? import ../extraSpecialArgs.nix {inherit inputs;},
  pkgs ? (import inputs.nixpkgs {
    inherit system;
    inherit (pkgsCfg.nixpkgs) config overlays;
  }),
  ...
}: let
  inherit (pkgs) lib;
  # Get repo packages
  configurations = import ../nixosConfigurations.nix {inherit inputs pkgsCfg myLib extraSpecialArgs;};
  nodes = import ../nodes.nix;

  mapNodeAttr = attr:
    lib.pipe nodes [
      (lib.mapAttrsToList (
        name: value:
          if !lib.isAttrs value
          then null
          else if lib.hasAttr attr value
          then "[\"${name}\"]=${lib.escapeShellArg (lib.getAttr attr value)}"
          else null
      ))
      (lib.filter (v: v != null))
    ];

  ipMap = mapNodeAttr "ip";
  userMap = mapNodeAttr "user";

  systemsMap =
    lib.mapAttrsToList (
      name: value: "[\"${name}\"]=${
        lib.escapeShellArg (
          lib.getAttrFromPath ["config" "nixpkgs" "hostPlatform" "system"] value
        )
      }"
    )
    configurations;

  systemdInhibit = action:
    lib.optionalString pkgs.stdenv.hostPlatform.isLinux
    /*
    bash
    */
    ''systemd-inhibit --mode=block --why="${action} configuration $node" --who="$(pwd)/maintainer/deploy.nix"'';
in
  pkgs.writeShellApplication {
    name = "deploy-configuration";
    runtimeInputs = [pkgs.nix-output-monitor pkgs.nixos-rebuild-ng] ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [pkgs.systemd];
    text = ''
      if [[ $# -lt 2 ]]; then
        echo 'Error: deploy-configuration needs at least two arguments' >&2
        exit 1
      fi

      if ! [[ -f default.nix ]]; then
        echo 'Error: cwd missing default.nix' >&2
        exit 1
      fi

      node="$1"
      shift
      mode="$1"
      shift
      read -ra extra_args <<<"$@"

      declare -A ips=(${lib.concatStringsSep " " ipMap})
      declare -A users=(${lib.concatStringsSep " " userMap})
      declare -A systems=(${lib.concatStringsSep " " systemsMap})

      targetIP="''${ips["$node"]}"
      remoteUser="''${users["$node"]}"

      # Use an array here for intentional word splitting later
      sudoArg=("--sudo")
      [[ "$remoteUser" = root ]] && sudoArg=()

      userHost="$remoteUser@$targetIP"

      # Use an array for explicit word splitting
      buildHost=("--build-host" "$userHost")
      if [[ "${system}" = "''${systems["$node"]}" ]]; then
        echo "Building $node configuration locally"
        ${systemdInhibit "Building"} nom build -f . "nixosConfigurations.$node.config.system.build.toplevel" --no-link "''${extra_args[@]}"
        # shellcheck disable=SC2181
        # putting command directly in the if doesn't really word with nix generation
        if [[ "$?" != 0 ]]; then
          echo "Error: failed to build $node configuration" >&2
          exit 1
        fi
        buildHost=()
      fi


      echo "Build host: ''${buildHost[*]}"
      echo "Sudo argument: ''${sudoArg[*]}"
      echo "Target host: $userHost"
      # we want to split the unquoted variables into multiple args for nixos-rebuild-ng
      # shellcheck disable=SC2086
      ${systemdInhibit "Deploying"} nixos-rebuild-ng --no-reexec "''${buildHost[@]}" --target-host "$userHost" "''${sudoArg[@]}" --attr "nixosConfigurations.$node" "$mode"
    '';
  }
