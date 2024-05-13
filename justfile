
hostname := `hostname`
arch := `uname -m`

default:
    @just --list

build host=hostname:
    @nix build ".#nixosConfigurations.{{host}}.config.system.build.toplevel"

switch:
    @nh os switch

boot:
    @nh os boot

test:
    @nh os test

check:
    @nix flake check

deploy node="fermi":
    @nix run 'github:serokell/deploy-rs' '.#{{node}}' -- -- --impure

rekey:
    @sops updatekeys -y host/secrets.yaml
    @sops updatekeys -y host/srv_secrets.yaml
    @sops updatekeys -y home/secrets.yaml

iso variant="minimal" arch=arch:
    @nix build ".#nixosConfigurations.iso-{{variant}}-{{arch}}-linux.config.system.build.isoImage"

vm variant="minimal" arch=arch:
    @just iso {{variant}} {{arch}}
    @find result/iso -type f -name "*.iso" | head -n1 | xargs nix run 'nixpkgs#qemu_kvm' -- -boot d -smbios type=0,uefi=on -m 2G -cdrom
