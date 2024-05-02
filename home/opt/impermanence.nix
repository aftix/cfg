{
  lib,
  config,
  home-impermanence,
  ...
}: let
  cfg = config.my.impermanence;
in {
  imports = [home-impermanence];

  options.my.impermanence = {
    enable = lib.mkOption {default = true;};
    path = lib.mkOption {default = "${config.home.homeDirectory}/.local/persist";};
  };

  config.home.persistence.${cfg.path} = lib.mkIf cfg.enable {
    directories = [
      ".config/sops"
    ];
    allowOther = true;
  };
}
