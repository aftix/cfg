{
  config,
  pkgs,
  lib,
  ...
}: {
  home =
    {
      packages = [pkgs.element-desktop];
    }
    // lib.optionalAttrs (config.my ? impermanence && config.my.impermanence.enable) {
      persistence.${config.my.impermanence.path} = {
        directories = [
          ".config/Element"
        ];
      };
    };

  my.element = true;
}
