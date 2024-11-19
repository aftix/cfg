{
  config,
  lib,
  pkgs,
  stylix,
  ...
}: {
  imports = [stylix];
  home.packages = [pkgs.base16-schemes];

  stylix = {
    enable = true;
    image = ./wallpaper.jpg;
    polarity = "dark";
    # Issue with IFD: https://github.com/danth/stylix/issues/625
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/atelier-sulphurpool.yaml";
    base16Scheme = {
      system = "base16";
      name = "Atelier Sulphurpool";
      author = "Bram de Haan (http =//atelierbramdehaan.nl)";
      variant = "dark";
      palette = {
        base00 = "202746";
        base01 = "293256";
        base02 = "5e6687";
        base03 = "6b7394";
        base04 = "898ea4";
        base05 = "979db4";
        base06 = "dfe2f1";
        base07 = "f5f7ff";
        base08 = "c94922";
        base09 = "c76b29";
        base0A = "c08b30";
        base0B = "ac9739";
        base0C = "22a2c9";
        base0D = "3d8fd1";
        base0E = "6679cc";
        base0F = "9c637a";
      };
    };

    fonts = {
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };

      sansSerif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };

      monospace = {
        package = pkgs.inconsolata;
        name = "Inconsolata";
      };

      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };

      sizes = {
        applications = 12;
        terminal = 24;
        desktop = 10;
        popups = 12;
      };
    };

    cursor = {
      package = pkgs.rose-pine-cursor;
      name = "BreezeX-RosePine-Linux";
    };

    opacity.terminal = 0.9;

    targets = {
      tofi.enable = true;
      helix.enable = false;
      xresources.enable = false;
      sxiv.enable = false;

      kde.enable = lib.strings.hasSuffix "-linux" pkgs.system;
      gnome.enable = lib.strings.hasSuffix "-linux" pkgs.system;
    };
  };

  # Manually override a specific value from stylix's helix theme
  xdg.configFile."helix/themes/stylix.toml".source = let
    theme = config.lib.stylix.colors {
      templateRepo = config.lib.stylix.templates.base16-helix;
    };

    transparentTheme = pkgs.runCommandLocal "helix-transparent.toml" {} ''
      sed 's/,\? bg = "base00"//g' <${theme} >$out
    '';

    patchTheme = {
      theme,
      key,
      value,
    }:
      pkgs.runCommandLocal "helix-patched.toml" {} ''
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
