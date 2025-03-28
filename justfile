
hostname := `hostname`
arch := `uname -m`

default:
    @just --list

attic-push path cache="cfg-actions":
    @if [[ -e "{{path}}" ]]; then nix-store --query --requisites --include-outputs "{{path}}" | xargs attic push "{{cache}}" &> /dev/null ; fi

buildpkg pkg cache="cfg-actions":
    # Build the package
    @nom build -f packages.nix '{{pkg}}'
    # Push the package build to attic
    @[[ -n "{{cache}}" ]] && for OUTPATH in $(nix eval -f packages.nix --raw --apply 'x: builtins.toString (builtins.map (pkg: pkg.outPath) ((x {}).{{pkg}}.all))'); do \
        if [[ -e "$OUTPATH" ]]; then \
            (nix-store --query --requisites --include-outputs "$OUTPATH" | xargs attic push "{{cache}}" &> /dev/null ) || : ; \
        fi \
    done

buildpkgs cache="cfg-actions":
    #!/usr/bin/env bash
    echo "Determining package list"
    NPKGS="$(nix eval -f packages.nix --apply 'x: let
        inputs = import ./flake-compat/inputs.nix;
        packages = x {inherit inputs;};
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
        nom build -f packages.nix "$pkg" --no-link || :
    done
    echo "Determing derivations to push to attic"
    OUTPATHS="$(nix eval -f packages.nix --apply 'x: let
        inputs = import ./flake-compat/inputs.nix;
        packages = x {inherit inputs;};
        inherit (inputs.nixpkgs) lib;
        getDrvs = lib.filterAttrs (name: value: lib.isDerivation value || value.recurseForDerivations or false);
        drvs = lib.concatMapAttrs (
            name: value:
                if lib.isDerivation value then {${name} = value;}
                else if lib.isAttrs value then {${name} = getDrvs value;}
                else {}
            ) packages;
        getOutPaths = val: if lib.isDerivation val then
                builtins.map (lib.getAttr "outPath") val.all
            else if lib.isAttrs val then
                lib.flatten (lib.mapAttrsToList (_: getOutPaths) val)
            else [];
        outPaths = lib.flatten (getOutPaths drvs);
        in lib.concatStringsSep " " outPaths' --impure --raw)"
    if [[ -n "{{cache}}" ]]; then
        echo "Pushing derivations to attic"
        for OUTPATH in $OUTPATHS ; do
            if [[ -e "$OUTPATH" ]]; then
                (nix-store --query --requisites --include-outputs "$OUTPATH" | xargs attic push "{{cache}}" &> /dev/null ) || :
            fi
        done
    fi

build host=hostname *FLAGS="":
    # Build configuration
    @nom build -f . "nixosConfigurations.{{host}}.config.system.build.toplevel" {{FLAGS}}
    # Push configuration build to attic
    @(nix eval -f . --apply 'self: let \
        build = self.nixosConfigurations.{{host}}.config.system.build.toplevel; \
        drvs = builtins.map (drv: drv.outPath) build.all; \
        in builtins.toString drvs' --raw | tr ' ' '\n' | xargs -n1 just attic-push) || :

switch *FLAGS:
    # Build configuration
    @nom build -f . "nixosConfigurations.{{hostname}}.config.system.build.toplevel" --no-link {{FLAGS}}
    # Run nixos-rebuild-ng
    @run0 nixos-rebuild-ng --attr "nixosConfigurations.{{hostname}}" switch
    # Push configuration build to attic
    @(nix eval -f . "nixosConfigurations.{{hostname}}.config.system.build.toplevel" --apply 'x: builtins.toString (builtins.map (drv: drv.outPath) x.all)' --raw \
        | tr ' ' '\n' | xargs -n1 just attic-push) || :

boot *FLAGS:
    # Build configuration
    @nom build -f . "nixosConfigurations.{{hostname}}.config.system.build.toplevel" --no-link {{FLAGS}}
    # Run nixos-rebuild-ng
    @run0 nixos-rebuild-ng --attr "nixosConfigurations.{{hostname}}" boot
    # Push configuration build to attic
    @(nix eval -f . "nixosConfigurations.{{hostname}}.config.system.build.toplevel" --apply 'x: builtins.toString (builtins.map (drv: drv.outPath) x.all)' --raw \
        | tr ' ' '\n' | xargs -n1 just attic-push) || :

test *FLAGS:
    # Build configuration
    @nom build -f . "nixosConfigurations.{{hostname}}.config.system.build.toplevel" --no-link {{FLAGS}}
    # Run nixos-rebuild-ng
    @run0 nixos-rebuild-ng --attr "nixosConfigurations.{{hostname}}" test
    # Push configuration build to attic
    @(nix eval -f . "nixosConfigurations.{{hostname}}.config.system.build.toplevel" --apply 'x: builtins.toString (builtins.map (drv: drv.outPath) x.all)' --raw \
        | tr ' ' '\n' | xargs -n1 just attic-push) || :

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
        nom build -f . "nixosConfigurations.{{node}}.config.system.build.toplevel" --no-link {{FLAGS}}
        BUILD_HOST=""
        echo "Pushing {{node}} derivations to attic"
        (nix eval -f . "nixosConfigurations.{{node}}.config.system.build.toplevel" --apply 'x: builtins.toString (builtins.map (drv: drv.outPath) x.all)' --raw \
            | tr ' ' '\n' | xargs -n1 just attic-push) || :
    fi
    SUDO="--sudo"
    [[ "$BUILD_USER" = "root" ]] && SUDO=""
    echo "BUILD_HOST: $BUILD_HOST"
    echo "SUDO: $SUDO"
    echo "TARGET_HOST: $TARGET_HOST"
    nixos-rebuild-ng $BUILD_HOST --target-host "${BUILD_USER}@${IP}" $SUDO --attr "nixosConfigurations.{{node}}" "{{mode}}"

rekey:
    @sops updatekeys -y host/secrets.yaml
    @sops updatekeys -y host/srv_secrets.yaml
    @sops updatekeys -y home/secrets.yaml

iso variant="minimal" *FLAGS="":
    # Build ISO
    @nom build --impure --expr '(import ./.).nixosConfigurations.iso-{{variant}}.config.system.build.isoImage' {{FLAGS}}
    # Push ISO build to attic
    @(nix eval -f . --apply 'self: let \
        inherit (self.nixosConfigurations.iso-{{variant}}.config.system.build) isoImage; \
        drvs = builtins.map (drv: drv.outPath) isoImage.all; \
        in builtins.toString drvs' --raw --impure | tr ' ' '\n' | xargs -n1 just attic-push) || :

vm variant="minimal" *FLAGS="":
    @just iso {{variant}}
    # Run VM
    @find result/iso -type f -name "*.iso" | head -n1 | xargs -I% nix run 'nixpkgs#qemu_kvm' -- -boot d -smbios type=0,uefi=on -m 2G -cdrom % {{FLAGS}}

serialvm variant="minimal" *FLAGS="":
    @just iso {{variant}}
    # Run VM
    @find result/iso -type f -name "*.iso" | head -n1 | xargs -I% nix run 'nixpkgs#qemu_kvm' -- -boot d -smbios type=0,uefi=on -m 2G -nographic -serial mon:stdio -cdrom % {{FLAGS}}
