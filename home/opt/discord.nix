{
  config,
  lib,
  pkgs,
  ...
}: {
  home =
    {
      packages = with pkgs; [
        discord
        betterdiscordctl
      ];
    }
    // lib.optionalAttrs (config.my ? impermanence && config.my.impermanence.enable) {
      persistence.${config.my.impermanence.path} = {
        directories = [
          ".config/discord"
          ".config/BetterDiscord"
        ];
      };
    };
}
