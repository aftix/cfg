{
  config,
  lib,
  upkgs,
  ...
}: {
  home.persistence.${config.my.impermanence.path} = lib.mkIf config.my.impermanence.enable {
    directories = [
      ".config/chromium"
    ];
  };

  programs.chromium = {
    enable = true;
    package = upkgs.ungoogled-chromium;
    dictionaries = [upkgs.hunspellDictsChromium.en_US];
  };
}
