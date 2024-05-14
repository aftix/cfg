{
  config,
  sops-nix,
  ...
}: let
  keyFile = config.home.homeDirectory + "/.local/persist/.config/sops/age/keys.txt";
in {
  imports = [sops-nix];

  sops = {
    defaultSopsFile = ../secrets.yaml;

    age = {inherit keyFile;};
  };
}
