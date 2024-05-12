
hostname := `hostname`

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

iso variant="minimal" arch="x86_64-linux":
    @nix build ".#nixosConfigurations.iso-{{variant}}-{{arch}}.config.system.build.isoImage"
