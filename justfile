
hostname := `hostname`
arch := `uname -m`

default:
    @just --list

attic-push path cache="cfg-actions":
    @if [[ -e "{{path}}" ]]; then \
        nix-store --query --requisites --include-outputs "{{path}}" \
        | systemd-inhibit --mode=block --why="Pushing artifacts" --who="$(pwd)/justfile" \
            xargs attic push "{{cache}}" &> /dev/null ; \
    fi

buildpkg pkg cache="cfg-actions":
    # Build the package
    @systemd-inhibit --mode=block --why="Building package {{pkg}}" --who="$(pwd)/justfile" nom build -f packages.nix '{{pkg}}'

buildpkgs cache="cfg-actions":
    #!/usr/bin/env bash
    echo "Determining package list"
    NPKGS="$(nix eval -f packages.nix --apply 'x: let
        packages = x {};
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
        systemd-inhibit --mode=block --why="Building package $pkg" --who="$(pwd)/justfile" nom build -f packages.nix "$pkg" --no-link || :
    done

build host=hostname *FLAGS="":
    # Build configuration
    @systemd-inhibit --mode=block --why="Building configuration {{host}}" --who="$(pwd)/justfile" \
        nom build -f . "nixosConfigurations.{{host}}.config.system.build.toplevel" {{FLAGS}}

switch *FLAGS:
    # Build configuration
    @systemd-inhibit --mode=block --why="Building configuration {{hostname}}" --who="$(pwd)/justfile" \
        nom build -f . "nixosConfigurations.{{hostname}}.config.system.build.toplevel" --no-link {{FLAGS}}
    # Run nixos-rebuild-ng
    @run0 systemd-inhibit --mode=block --why="Switching to new configuration" --who="$(pwd)/justfile" \
        nixos-rebuild-ng --attr "nixosConfigurations.{{hostname}}" switch

boot *FLAGS:
    # Build configuration
    @systemd-inhibit --mode=block --why="Building configuration {{hostname}}" --who="$(pwd)/justfile" \
        nom build -f . "nixosConfigurations.{{hostname}}.config.system.build.toplevel" --no-link {{FLAGS}}
    # Run nixos-rebuild-ng
    @run0 systemd-inhibit --mode=block --why="Switching boot menu default" --who="$(pwd)/justfile" \
        nixos-rebuild-ng --attr "nixosConfigurations.{{hostname}}" boot

test *FLAGS:
    # Build configuration
    @systemd-inhibit --mode=block --why="Building configuration {{hostname}}" --who="$(pwd)/justfile" \
        nom build -f . "nixosConfigurations.{{hostname}}.config.system.build.toplevel" --no-link {{FLAGS}}
    # Run nixos-rebuild-ng
    @run0 systemd-inhibit --mode=block --why="Activating new configuration" --who="$(pwd)/justfile" \
        nixos-rebuild-ng --attr "nixosConfigurations.{{hostname}}" test

check *FLAGS:
    @nix flake check {{FLAGS}}

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
