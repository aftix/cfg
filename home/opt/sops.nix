{
  config,
  sops,
  ...
}: let
  keyFile = config.home.homeDirectory + "/.local/persist/${config.home.homeDirectory}/.config/sops/age/keys.txt";
in {
  imports = [sops];

  sops = {
    defaultSopsFile = ../../secrets/home/secrets.yaml;

    age = {inherit keyFile;};
  };
}
