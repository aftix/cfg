{
  config,
  sops-nix,
  ...
}: {
  imports = [sops-nix];

  sops = {
    defaultSopsFile = ../secrets.yaml;

    age.keyFile = "${config.home.homeDirectory}/.local/persist/.config/sops/age/keys.txt";
  };
}
