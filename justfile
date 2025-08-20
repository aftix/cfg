# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
hostname := `hostname`
arch := `uname -m`

default:
    @just --list

updatepkg pkg:
    #!/usr/bin/env bash
    if [[ "$(jj log -r @ --no-graph -T "if(self.empty(), 1, 0)")" != 1 ]]; then
        echo 'Error: running `just updatepkg` on non-empty commit' >&2
        exit 1
    fi

    if ! nix eval -f packages.nix '{{pkg}}' &>/dev/null ; then
        echo 'Error: {{pkg}} not found in packages.nix' &>/dev/null
        exit 1
    fi

    echo "Getting version-update string"
    VERSION="$(nix eval --raw -f packages.nix --apply 'x: ((x {}).{{pkg}}.meta or {}).updateVersion or "stable"')"

    if [[ "$VERSION" = "none" ]]; then
        echo "Skipping {{pkg}} as it does not update via nix-update"
        exit 0
    fi

    echo "Running nix-update"
    systemd-inhibit --mode=block --why="Updating package {{pkg}}" --why="$(pwd)/justfile" \
        nix run github:Mic92/nix-update -- -f packages.nix {{pkg}} --version="$VERSION"
    if [[ "$?" -ne 0 ]]; then
        echo 'Error: Failed to update package {{pkg}}' >&2
        exit 1
    fi

    if [[ "$(jj log -r @ --no-graph -T "if(self.empty(), 1, 0)")" = 1 ]]; then
        echo "No updates found"
        exit 0
    fi

    echo "Checking if the package builds"
    systemd-inhibit --mode=block --why="Building package {{pkg}}" --who="$(pwd)/justfile" \
        nom build -f packages.nix '{{pkg}}' --no-link --print-out-paths

    if [[ "$?" -eq 0 ]]; then
        echo "Package built"
        jj ci -m "chore(legacyPackages.{{pkg}}): update to latest $VERSION" --quiet
    else
        echo "Package not built, abandoning change" >&2
        jj abandon --quiet
        exit 1
    fi

updatepkgs:
    #!/usr/bin/env bash
    echo "Determining package list"
    NPKGS="$(nix eval -f packages.nix --apply 'x: let
        packages = x {};
        inputs = import ./inputs.nix;
        inherit (inputs.nixpkgs) lib;
        getDrvs = lib.filterAttrs (name: value: lib.isDerivation value || value.recurseForDerivations or false);
        drvs = lib.concatMapAttrs (
            name: value:
                if lib.isDerivation value then {${name} = value;}
                else if lib.isAttrs value then {${name} = getDrvs value;}
                else {}
            ) packages;
        convert = prefix: lib.mapAttrsToList (
            name: value: let fullname = "${prefix}${lib.optionalString (prefix != "") "."}${name}"; in
                if lib.isAttrs value && !lib.isDerivation value then
                    convert fullname value
                else
                    fullname
            );
        drvNames = lib.flatten (convert "" drvs);
        in lib.concatStringsSep " " drvNames' --impure --raw)"

    echo "Updating packages"
    COUNTER=0
    for pkg in $NPKGS; do
        echo "updating $pkg"
        just updatepkg "$pkg"
        COUNTER=$(( COUNTER + 1 ))
    done

    echo "Updated $COUNTER packages"

attic-push path cache="cfg-actions":
    @if [[ -e "{{path}}" ]]; then \
        nix-store --query --requisites --include-outputs "{{path}}" \
        | systemd-inhibit --mode=block --why="Pushing artifacts" --who="$(pwd)/justfile" \
            xargs attic push "{{cache}}" &> /dev/null ; \
    fi

buildpkg pkg:
    @systemd-inhibit --mode=block --why="Building package {{pkg}}" --who="$(pwd)/justfile" \
        nom build -f packages.nix '{{pkg}}' --no-link --print-out-paths

buildpkgs:
    #!/usr/bin/env bash
    echo "Determining package list"
    NPKGS="$(nix eval -f packages.nix --apply 'x: let
        packages = x {};
        inputs = import ./inputs.nix;
        inherit (inputs.nixpkgs) lib;
        getDrvs = lib.filterAttrs (name: value: lib.isDerivation value || value.recurseForDerivations or false);
        drvs = lib.concatMapAttrs (
            name: value:
                if lib.isDerivation value then {${name} = value;}
                else if lib.isAttrs value then {${name} = getDrvs value;}
                else {}
            ) packages;
        convert = prefix: lib.mapAttrsToList (
            name: value: let fullname = "${prefix}${lib.optionalString (prefix != "") "."}${name}"; in
                if lib.isAttrs value && !lib.isDerivation value then
                    convert fullname value
                else
                    fullname
            );
        drvNames = lib.flatten (convert "" drvs);
        in lib.concatStringsSep " " drvNames' --impure --raw)"
    echo "Building packages"
    for pkg in $NPKGS; do
        echo "Building $pkg"
        systemd-inhibit --mode=block --why="Building package $pkg" --who="$(pwd)/justfile" nom build -f packages.nix "$pkg" --no-link --print-out-paths || :
    done

build host=hostname *FLAGS="":
    # Build configuration
    @systemd-inhibit --mode=block --why="Building configuration {{host}}" --who="$(pwd)/justfile" \
        nom build -f . "nixosConfigurations.{{host}}.config.system.build.toplevel" --no-link --print-out-paths {{FLAGS}}

switch *FLAGS:
    # Build configuration
    @systemd-inhibit --mode=block --why="Building configuration {{hostname}}" --who="$(pwd)/justfile" \
        nom build -f . "nixosConfigurations.{{hostname}}.config.system.build.toplevel" --no-link {{FLAGS}}
    # Run nixos-rebuild-ng
    @systemd-inhibit --mode=block --why="Switching to new configuration" --who="$(pwd)/justfile" \
        nixos-rebuild-ng --attr "nixosConfigurations.{{hostname}}" --sudo switch

boot *FLAGS:
    # Build configuration
    @systemd-inhibit --mode=block --why="Building configuration {{hostname}}" --who="$(pwd)/justfile" \
        nom build -f . "nixosConfigurations.{{hostname}}.config.system.build.toplevel" --no-link {{FLAGS}}
    # Run nixos-rebuild-ng
    @systemd-inhibit --mode=block --why="Switching boot menu default" --who="$(pwd)/justfile" \
        nixos-rebuild-ng --attr "nixosConfigurations.{{hostname}}" --sudo boot

test *FLAGS:
    # Build configuration
    @systemd-inhibit --mode=block --why="Building configuration {{hostname}}" --who="$(pwd)/justfile" \
        nom build -f . "nixosConfigurations.{{hostname}}.config.system.build.toplevel" --no-link {{FLAGS}}
    # Run nixos-rebuild-ng
    @systemd-inhibit --mode=block --why="Activating new configuration" --who="$(pwd)/justfile" \
        nixos-rebuild-ng --attr "nixosConfigurations.{{hostname}}" --sudo test

deploy node="fermi" mode="switch" *FLAGS="":
    #!/usr/bin/env bash
    IP="$(nix eval --raw -f nodes.nix --apply 'x: x.{{node}}.ip')"
    BUILD_USER="$(nix eval --raw -f nodes.nix --apply 'x: x.{{node}}.user')"
    BUILD_HOST="--build-host ${BUILD_USER}@${IP}"
    if [[ "$(nix eval --impure --raw -E 'builtins.currentSystem')" = \
        "$(nix eval --raw -f . --apply 'x: x.nixosConfigurations.{{node}}.config.nixpkgs.hostPlatform.system')" ]]; then
        echo "Building {{node}} configuration locally"
        systemd-inhibit --mode=block --why="Building configuration {{node}}" --who="$(pwd)/justfile" \
            nom build -f . "nixosConfigurations.{{node}}.config.system.build.toplevel" --no-link {{FLAGS}}
        BUILD_HOST=""
    fi
    SUDO="--sudo"
    [[ "$BUILD_USER" = "root" ]] && SUDO=""
    echo "BUILD_HOST: $BUILD_HOST"
    echo "SUDO: $SUDO"
    echo "TARGET_HOST: ${BUILD_USER}@${IP}"
    systemd-inhibit --mode=block --why="Deploying configuration {{node}} to $IP" --who="$(pwd)/justfile" \
        nixos-rebuild-ng --no-reexec $BUILD_HOST --target-host "${BUILD_USER}@${IP}" $SUDO --attr "nixosConfigurations.{{node}}" "{{mode}}"

rekey:
    @sops updatekeys -y host/secrets.yaml
    @sops updatekeys -y host/srv_secrets.yaml
    @sops updatekeys -y home/secrets.yaml

iso variant="minimal" *FLAGS="":
    # Build ISO
    @systemd-inhibit --mode=block --why="Building {{variant}} iso" --who="$(pwd)/justfile" \
        nom build --impure --expr '(import ./.).nixosConfigurations.iso-{{variant}}.config.system.build.isoImage' {{FLAGS}}
    # Push ISO build to attic
    @(nix eval -f . --apply 'self: let \
        inherit (self.nixosConfigurations.iso-{{variant}}.config.system.build) isoImage; \
        drvs = builtins.map (drv: drv.outPath) isoImage.all; \
        in builtins.toString drvs' --raw --impure | tr ' ' '\n' | \
        systemd-inhibit --mode=block --why="Pushing artifacts" --who="$(pwd)/justfile" xargs -n1 just attic-push) || :

vm variant="minimal" *FLAGS="":
    @just iso {{variant}}
    # Run VM
    @find result/iso -type f -name "*.iso" | head -n1 | xargs -I% nix run 'nixpkgs#qemu_kvm' -- -boot d -smbios type=0,uefi=on -m 2G -cdrom % {{FLAGS}}

serialvm variant="minimal" *FLAGS="":
    @just iso {{variant}}
    # Run VM
    @find result/iso -type f -name "*.iso" | head -n1 | xargs -I% nix run 'nixpkgs#qemu_kvm' -- -boot d -smbios type=0,uefi=on -m 2G -nographic -serial mon:stdio -cdrom % {{FLAGS}}

licenses:
    @reuse lint

download-license LICENSE:
    @reuse download {{LICENSE}} -o LICENSES/{{LICENSE}}.md

annotate-file PATH:
    @reuse annotate -t default --copyright "aftix" --license EUPL-1.2 --year 2025 --copyright-prefix spdx-c --style python --merge-copyrights -r {{PATH}}

# Build a specific check from ./checks (attrpath is relative to "checks")
build-check check use-nom="1":
    #!/usr/bin/env bash
    USE_NOM_LOCAL="{{use-nom}}"
    USE_NOM="${USE_NOM:-${USE_NOM_LOCAL}}"
    nix-instantiate -E 'let
        system = builtins.currentSystem;
        jobs = import ./hydraJobs.nix {inherit system;};
    in
        jobs.checks.{{check}}.${system}
    ' | while read -r drv; do
        if [[ -n "$USE_NOM" && ! "$USE_NOM" = "0" ]]; then
            nom-build --no-out-link "$drv"
        else
            nix-build --no-out-link "$drv"
        fi
    done

check use-nom="1":
    #!/usr/bin/env bash
    USE_NOM_LOCAL="{{use-nom}}"
    USE_NOM="${USE_NOM:-${USE_NOM_LOCAL}}"
    nix-instantiate -E 'let
        system = builtins.currentSystem;
        jobs = (import ./hydraJobs.nix {inherit system;}).checks;
        inputs = import ./inputs.nix;
        matchesSystemRaw = pkgs.lib.mapAttrsRecursiveCond (as:
            ! pkgs.lib.isDerivation as && ! builtins.hasAttr system as
            )
            (path: value:
                if builtins.hasAttr system value 
                then builtins.getAttr system value
                else {}
            ) jobs;
        matchesSystem = pkgs.lib.collect pkgs.lib.isDerivation matchesSystemRaw;
        pkgs = import inputs.nixpkgs {inherit system;};
    in
        pkgs.linkFarmFromDrvs "all-checks" matchesSystem
    ' | while read -r drv; do
        if [[ -n "$USE_NOM" && ! "$USE_NOM" = "0" ]]; then
            nom-build --no-out-link "$drv"
        else
            nix-build --no-out-link "$drv"
        fi
    done
