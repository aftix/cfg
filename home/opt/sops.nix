{
  config,
  sops-nix,
  ...
}: {
  imports = [sops-nix];

  sops = {
    defaultSopsFile = ../secrets.yaml;

    age.keyFile = "${config.home.homeDirectory}/.local/persist/.config/sops/age/keys.txt";

    secrets = {
      "private_keys/aftix".path = "${config.home.homeDirectory}/.ssh/id_ed25519";
    };
  };
}
