# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
hostname := `hostname`
arch := `uname -m`

default:
    @just --list

updatepkg pkg:
    "$(nix build -f maintainer/update-packages.nix --no-link --print-out-paths)/bin/update-package" {{pkg}}

updatepkgs:
    "$(nix build -f maintainer/update-packages.nix --no-link --print-out-paths)/bin/update-package"

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
    pkgs="$(nix eval -f maintainer/all-packages.nix --raw --apply 'x: x {}')"
    counter=0
    failcounter=0
    echo "Building packages"
    for pkg in $pkgs; do
        echo "Building $pkg"
        systemd-inhibit --mode=block --why="Building package $pkg" --who="$(pwd)/justfile" nom build -f packages.nix "$pkg" --no-link --print-out-paths || :
        if [[ "$?" = 0 ]]; then
            ((counter++)) || :
        else
            ((failcounter++)) || :
        fi
    done
    echo "Successfully built $counter packages, failed to build $failcounter packages."

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
