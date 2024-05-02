{
  config,
  lib,
  upkgs,
  ...
}: {
  home.persistence.${config.my.impermanence.path} = lib.mkIf config.my.impermanence.enable {
    directories = [
      ".config/discord"
      ".config/BetterDiscord"
    ];
  };

  home.packages = with upkgs; [
    discord
    betterdiscordctl
  ];
}
