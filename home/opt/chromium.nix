{
  config,
  lib,
  pkgs,
  ...
}: {
  home.persistence.${config.my.impermanence.path} = lib.mkIf config.my.impermanence.enable {
    directories = [
      ".config/chromium"
    ];
  };

  programs.chromium = {
    enable = true;
    package = pkgs.ungoogled-chromium;
    dictionaries = [pkgs.hunspellDictsChromium.en_US];
  };
}
