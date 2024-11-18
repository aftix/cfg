
hostname := `hostname`
arch := `uname -m`

default:
    @just --list

attic-push path cache="cfg-actions":
    @if [[ -e "{{path}}" ]]; then nix-store --query --requisites --include-outputs "{{path}}" | xargs attic push "{{cache}}" &> /dev/null ; fi

buildpkg pkg cache="cfg-actions":
    @nom build '.#{{pkg}}'
    @[[ -n "{{cache}}" ]] && for OUTPATH in $(nix eval '.#{{pkg}}' --raw --apply 'x: builtins.toString (builtins.map (pkg: pkg.outPath) x.all)'); do \
        if [[ -e "$OUTPATH" ]]; then \
            (nix-store --query --requisites --include-outputs "$OUTPATH" | xargs attic push "{{cache}}" &> /dev/null ) || : ; \
        fi \
    done

buildpkgs cache="cfg-actions":
    #!/usr/bin/env bash
    NPKGS="$(nix eval '.#packages' --apply 'x: builtins.toString (builtins.attrNames x.${builtins.currentSystem})' --impure --raw)"
    for pkg in $NPKGS; do
        nom build ".#$pkg" || :
    done
    OUTPATHS="$(nix eval .#packages --apply 'x:
        let y = x.${builtins.currentSystem};
        names = builtins.attrNames y;
        all = builtins.map (name: y.${name}.all) names;
        drvs = builtins.foldl'"'"' (acc: lst: acc ++ lst) [] all;
        paths = builtins.map (drv: drv.outPath) drvs;
        in builtins.toString paths' --impure --raw)"
    for OUTPATH in $OUTPATHS ; do
        if [[ -e "$OUTPATH" ]]; then
            (nix-store --query --requisites --include-outputs "$OUTPATH" | xargs attic push "{{cache}}" &> /dev/null ) || :
        fi
    done

build host=hostname *FLAGS="":
    @nom build ".#nixosConfigurations.{{host}}.config.system.build.toplevel" {{FLAGS}}
    @(nix eval '.#nixosConfigurations.{{host}}.config.system.build.toplevel' --apply 'x: builtins.toString (builtins.map (drv: drv.outPath) x.all)' --raw \
        | tr ' ' '\n' | xargs -n1 just attic-push) || :

switch *FLAGS:
    @nixos apply . --use-nom {{FLAGS}}
    @(nix eval '.#nixosConfigurations.{{hostname}}.config.system.build.toplevel' --apply 'x: builtins.toString (builtins.map (drv: drv.outPath) x.all)' --raw \
        | tr ' ' '\n' | xargs -n1 just attic-push) || :

boot *FLAGS:
    @nixos apply . --use-nom --no-activate {{FLAGS}}
    @(nix eval '.#nixosConfigurations.{{hostname}}.config.system.build.toplevel' --apply 'x: builtins.toString (builtins.map (drv: drv.outPath) x.all)' --raw \
        | tr ' ' '\n' | xargs -n1 just attic-push) || :

test *FLAGS:
    @nixos apply . --use-nom --no-boot {{FLAGS}}
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
    @nom build ".#nixosConfigurations.iso-{{variant}}.config.system.build.isoImage" {{FLAGS}}
    @(nix eval '.#nixosConfigurations.iso-{{variant}}.config.system.build.isoImage' --apply 'x: builtins.toString (builtins.map (drv: drv.outPath) x.all)' --raw \
        | tr ' ' '\n' | xargs -n1 just attic-push) || :

vm variant="minimal" *FLAGS="":
    @just iso {{variant}}
    @find result/iso -type f -name "*.iso" | head -n1 | xargs -I% nix run 'nixpkgs#qemu_kvm' -- -boot d -smbios type=0,uefi=on -m 2G -cdrom % {{FLAGS}}

serialvm variant="minimal" *FLAGS="":
    @just iso {{variant}}
    @find result/iso -type f -name "*.iso" | head -n1 | xargs -I% nix run 'nixpkgs#qemu_kvm' -- -boot d -smbios type=0,uefi=on -m 2G -nographic -serial mon:stdio -cdrom % {{FLAGS}}
