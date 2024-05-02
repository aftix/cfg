{
  config,
  upkgs,
  stylix,
  ...
}: {
  home.packages = [upkgs.base16-schemes];

  imports = [stylix];

  stylix = {
    image = ./wallpaper.jpg;
    polarity = "dark";
    base16Scheme = "${upkgs.base16-schemes}/share/themes/tokyo-night-terminal-dark.yaml";
    override = {
      base03 = "808080";
      base05 = "eeeeee";
    };

    fonts = {
      serif = {
        package = upkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };

      sansSerif = {
        package = upkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };

      monospace = {
        package = upkgs.inconsolata;
        name = "Inconsolata";
      };

      emoji = {
        package = upkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };

      sizes = {
        applications = 12;
        terminal = 16;
        desktop = 10;
        popups = 12;
      };
    };

    cursor = {
      package = upkgs.rose-pine-cursor;
      name = "BreezeX-RosePine-Linux";
    };

    opacity.terminal = 0.5;

    targets = {
      helix.enable = false;
      kde.enable = upkgs.system == "x86_64-linux";
      gnome.enable = upkgs.system == "x86_64-linux";
    };
  };

  # Manually override a specific value from stylix's helix theme
  xdg.configFile."helix/themes/stylix.toml".source = let
    theme = config.lib.stylix.colors {
      templateRepo = config.lib.stylix.templates.base16-helix;
    };

    transparentTheme = upkgs.runCommandLocal "helix-transparent.toml" {} ''
      sed 's/,\? bg = "base00"//g' <${theme} >$out
    '';

    patchTheme = {
      theme,
      key,
      value,
    }:
      upkgs.runCommandLocal "helix-patched.toml" {} ''
        if grep --quiet '^"${key}"' ${theme} ; then
          sed 's/^"${key}".\+/"${key}" = ${value}/' <${theme} >$out
        else
          cp ${theme} $out
          echo '"${key}" = ${value}' >> $out
        fi
      '';
  in
    patchTheme {
      theme =
        if config.stylix.opacity.terminal == 1.0
        then theme
        else transparentTheme;
      key = "ui.text.focus";
      value = "\"base0E\"";
    };
}
