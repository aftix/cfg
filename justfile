
hostname := `hostname`
arch := `uname -m`

default:
    @just --list

build host=hostname *FLAGS="":
    @nom build ".#nixosConfigurations.{{host}}.config.system.build.toplevel" {{FLAGS}}

switch *FLAGS:
    @nh os switch {{FLAGS}}

boot *FLAGS:
    @nh os boot {{FLAGS}}

test *FLAGS:
    @nh os test {{FLAGS}}

check *FLAGS:
    @nix flake check {{FLAGS}}

deploy node="fermi" *FLAGS="":
    @nix run {{FLAGS}} 'github:serokell/deploy-rs' '.#{{node}}' -- -- --impure

deploy-override node="fermi":
    @just deploy {{node}} --inputs-from .

rekey:
    @sops updatekeys -y host/secrets.yaml
    @sops updatekeys -y host/srv_secrets.yaml
    @sops updatekeys -y home/secrets.yaml

iso variant="minimal" arch=arch *FLAGS="":
    @nom build ".#nixosConfigurations.iso-{{variant}}-{{arch}}-linux.config.system.build.isoImage" {{FLAGS}}

vm variant="minimal" arch=arch *FLAGS="":
    @just iso {{variant}} {{arch}}
    @find result/iso -type f -name "*.iso" | head -n1 | xargs -I% nix run 'nixpkgs#qemu_kvm' -- -boot d -smbios type=0,uefi=on -m 2G -cdrom % {{FLAGS}}

serialvm variant="minimal" arch=arch *FLAGS="":
    @just iso {{variant}} {{arch}}
    @find result/iso -type f -name "*.iso" | head -n1 | xargs -I% nix run 'nixpkgs#qemu_kvm' -- -boot d -smbios type=0,uefi=on -m 2G -nographic -serial mon:stdio -cdrom % {{FLAGS}}
