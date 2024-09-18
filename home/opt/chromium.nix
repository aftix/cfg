{
  config,
  lib,
  ...
}: let
  inherit (config.dep-inject) spkgs;
in {
  home.persistence.${config.my.impermanence.path} = lib.mkIf config.my.impermanence.enable {
    directories = [
      ".config/chromium"
    ];
  };

  programs.chromium = {
    enable = true;
    package = spkgs.ungoogled-chromium;
    dictionaries = [spkgs.hunspellDictsChromium.en_US];
  };
}
