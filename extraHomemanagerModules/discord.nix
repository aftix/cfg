# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{pkgs, ...}: {
  home.packages = with pkgs; [
    discord
    betterdiscordctl
  ];
}
