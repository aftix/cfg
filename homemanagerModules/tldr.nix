# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{pkgs, ...}: {
  home.packages = [pkgs.tealdeer];

  my.shell.upgradeCommands = [
    "tldr --update"
  ];

  xdg.configFile."tealdeer/config.toml".source = (pkgs.formats.toml {}).generate "tealdeer" {
    display.use_pager = true;
    updates.auto_update = true;
    style = {
      command_name.foreground = "green";
      example_code.foreground = "blue";
      example_variable = {
        foreground = "white";
        underline = true;
      };
    };
  };
}
