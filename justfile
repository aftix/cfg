
hostname := `hostname`
arch := `uname -m`

default:
    @just --list

attic-push path cache="cfg-actions":
    @if [[ -e "{{path}}" ]]; then nix-store --query --requisites --include-outputs "{{path}}" | xargs attic push "{{cache}}" &> /dev/null; fi

build host=hostname *FLAGS="":
    @nom build ".#nixosConfigurations.{{host}}.config.system.build.toplevel" {{FLAGS}}
    @just attic-push "./result" || :

switch *FLAGS:
    @nh os switch {{FLAGS}}

boot *FLAGS:
    @nh os boot {{FLAGS}}

test *FLAGS:
    @nh os test {{FLAGS}}

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

iso variant="minimal" arch=arch *FLAGS="":
    @nom build ".#nixosConfigurations.iso-{{variant}}-{{arch}}-linux.config.system.build.isoImage" {{FLAGS}}
    @just attic-push "./result" || :

vm variant="minimal" arch=arch *FLAGS="":
    @just iso {{variant}} {{arch}}
    @jut attic-push "./result"
    @find result/iso -type f -name "*.iso" | head -n1 | xargs -I% nix run 'nixpkgs#qemu_kvm' -- -boot d -smbios type=0,uefi=on -m 2G -cdrom % {{FLAGS}}

serialvm variant="minimal" arch=arch *FLAGS="":
    @just iso {{variant}} {{arch}}
    @just attic-push "./result" || :
    @find result/iso -type f -name "*.iso" | head -n1 | xargs -I% nix run 'nixpkgs#qemu_kvm' -- -boot d -smbios type=0,uefi=on -m 2G -nographic -serial mon:stdio -cdrom % {{FLAGS}}
