
hostname := `hostname`
arch := `uname -m`

default:
    @just --list

pre-build host=hostname *FLAGS="":
    @[[ "{{host}}" = "hamilton" ]] && nix build '.#waybar' --out-link .nixkeep-waybar {{FLAGS}}
    @[[ "{{host}}" = "hamilton" ]] && nix build '.#hyprland' --out-link .nixkeep-hyprland {{FLAGS}}

build host=hostname *FLAGS="":
    @just pre-build {{host}} {{FLAGS}}
    @nix build ".#nixosConfigurations.{{host}}.config.system.build.toplevel" {{FLAGS}}

switch *FLAGS:
    @just pre-build {{hostname}} {{FLAGS}}
    @nh os switch {{FLAGS}}

boot *FLAGS:
    @just pre-build {{hostname}} {{FLAGS}}
    @nh os boot {{FLAGS}}

test *FLAGS:
    @just pre-build {{hostname}} {{FLAGS}}
    @nh os test {{FLAGS}}

check *FLAGS:
    @nix flake check {{FLAGS}}

deploy node="fermi":
    @nix run 'github:serokell/deploy-rs' '.#{{node}}' -- -- --impure

rekey:
    @sops updatekeys -y host/secrets.yaml
    @sops updatekeys -y host/srv_secrets.yaml
    @sops updatekeys -y home/secrets.yaml

iso variant="minimal" arch=arch *FLAGS="":
    @nix build ".#nixosConfigurations.iso-{{variant}}-{{arch}}-linux.config.system.build.isoImage" {{FLAGS}}

vm variant="minimal" arch=arch *FLAGS="":
    @just iso {{variant}} {{arch}}
    @find result/iso -type f -name "*.iso" | head -n1 | xargs -I% nix run 'nixpkgs#qemu_kvm' -- -boot d -smbios type=0,uefi=on -m 2G -cdrom % {{FLAGS}}

serialvm variant="minimal" arch=arch *FLAGS="":
    @just iso {{variant}} {{arch}}
    @find result/iso -type f -name "*.iso" | head -n1 | xargs -I% nix run 'nixpkgs#qemu_kvm' -- -boot d -smbios type=0,uefi=on -m 2G -nographic -serial mon:stdio -cdrom % {{FLAGS}}
