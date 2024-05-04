{
  config,
  pkgs,
  lib,
  ...
}: {
  home.persistence.${config.my.impermanence.path} = lib.mkIf config.my.impermanence.enable {
    directories = [
      ".config/Element"
    ];
  };

  home.packages = [pkgs.element-desktop];
}
