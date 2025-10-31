# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
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
    base16Scheme = "${pkgs.base16-schemes}/share/themes/atelier-sulphurpool.yaml";

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
        package = pkgs.noto-fonts-color-emoji;
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
      size = 32;
    };

    opacity.terminal = 0.9;

    targets = {
      tofi.enable = true;
      helix.enable = false;
      xresources.enable = false;
      sxiv.enable = false;

      firefox.profileNames = ["aftix"];

      kde.enable = lib.strings.hasSuffix "-linux" pkgs.system;
      gnome.enable = lib.strings.hasSuffix "-linux" pkgs.system;
    };
  };

  # Manually override a specific value from stylix's helix theme
  xdg.configFile."helix/themes/stylix.toml".source = let
    theme = config.lib.stylix.colors {
      templateRepo = config.stylix.inputs.base16-helix;
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
