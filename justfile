
hostname := `hostname`
arch := `uname -m`

default:
    @just --list

attic-push path cache="cfg-actions":
    @if [[ -e "{{path}}" ]]; then nix-store --query --requisites --include-outputs "{{path}}" | xargs attic push "{{cache}}" &> /dev/null ; fi

buildpkg pkg cache="cfg-actions":
    @nom build -f packages.nix '{{pkg}}'
    @[[ -n "{{cache}}" ]] && for OUTPATH in $(nix eval -f packages.nix --raw --apply 'x: builtins.toString (builtins.map (pkg: pkg.outPath) ((x {}).{{pkg}}.all))'); do \
        if [[ -e "$OUTPATH" ]]; then \
            (nix-store --query --requisites --include-outputs "$OUTPATH" | xargs attic push "{{cache}}" &> /dev/null ) || : ; \
        fi \
    done

buildpkgs cache="cfg-actions":
    #!/usr/bin/env bash
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
    for pkg in $NPKGS; do
        nom build -f packages.nix "$pkg" || :
    done
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
    for OUTPATH in $OUTPATHS ; do
        if [[ -e "$OUTPATH" ]]; then
            (nix-store --query --requisites --include-outputs "$OUTPATH" | xargs attic push "{{cache}}" &> /dev/null ) || :
        fi
    done

build host=hostname *FLAGS="":
    #!/usr/bin/env bash
    nom build -f flake-compat/inputs.nix "self.nixosConfigurations.{{host}}.config.system.build.toplevel" {{FLAGS}}
    (nix eval -f flake-compat/inputs.nix --apply 'inputs: let
        build = inputs.self.nixosConfigurations.{{host}}.config.system.build.toplevel;
        drvs = builtins.map (drv: drv.outPath) build.all;
        in builtins.toString drvs' --raw | tr ' ' '\n' | xargs -n1 just attic-push) || :

switch *FLAGS:
    @nixos apply . --use-nom {{FLAGS}}
    # Use flakes here since the git revision is different
    @(nix eval '.#nixosConfigurations.{{hostname}}.config.system.build.toplevel' --apply 'x: builtins.toString (builtins.map (drv: drv.outPath) x.all)' --raw \
        | tr ' ' '\n' | xargs -n1 just attic-push) || :

boot *FLAGS:
    @nixos apply . --use-nom --no-activate {{FLAGS}}
    # Use flakes here since the git revision is different
    @(nix eval '.#nixosConfigurations.{{hostname}}.config.system.build.toplevel' --apply 'x: builtins.toString (builtins.map (drv: drv.outPath) x.all)' --raw \
        | tr ' ' '\n' | xargs -n1 just attic-push) || :

test *FLAGS:
    @nixos apply . --use-nom --no-boot {{FLAGS}}
    # Use flakes here since the git revision is different
    @(nix eval '.#nixosConfigurations.{{hostname}}.config.system.build.toplevel' --apply 'x: builtins.toString (builtins.map (drv: drv.outPath) x.all)' --raw \
        | tr ' ' '\n' | xargs -n1 just attic-push) || :

check *FLAGS:
    @nix flake check {{FLAGS}}

deploy node="fermi" *FLAGS="":
    @nom build {{FLAGS}} --out-link .deploy-rs 'github:serokell/deploy-rs'
    @just attic-push "./.deploy-rs" || :
    @nix run {{FLAGS}} 'github:serokell/deploy-rs' '.#{{node}}' -- -- --impure

deploy-override node="fermi":
    @just deploy {{node}} --inputs-from .

rekey:
    @sops updatekeys -y host/secrets.yaml
    @sops updatekeys -y host/srv_secrets.yaml
    @sops updatekeys -y home/secrets.yaml

iso variant="minimal" *FLAGS="":
    #!/usr/bin/env bash
    nom build --impure --expr '(import ./flake-compat/inputs.nix).self.nixosConfigurations.iso-{{variant}}.config.system.build.isoImage' {{FLAGS}}
    (nix eval -f flake-compat/inputs.nix --apply 'inputs: let
        inherit (inputs.self.nixosConfigurations.iso-{{variant}}.config.system.build) isoImage;
        drvs = builtins.map (drv: drv.outPath) isoImage.all;
        in builtins.toString drvs' --raw --impure | tr ' ' '\n' | xargs -n1 just attic-push) || :

vm variant="minimal" *FLAGS="":
    @just iso {{variant}}
    @find result/iso -type f -name "*.iso" | head -n1 | xargs -I% nix run 'nixpkgs#qemu_kvm' -- -boot d -smbios type=0,uefi=on -m 2G -cdrom % {{FLAGS}}

serialvm variant="minimal" *FLAGS="":
    @just iso {{variant}}
    @find result/iso -type f -name "*.iso" | head -n1 | xargs -I% nix run 'nixpkgs#qemu_kvm' -- -boot d -smbios type=0,uefi=on -m 2G -nographic -serial mon:stdio -cdrom % {{FLAGS}}
