# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{pkgs, ...}: {
  programs.zathura = {
    enable = true;

    options = {
      guioptions = "none";
      statusbar-h-padding = 0;
      statusbar-v-padding = 0;
      page-padding = 1;
    };

    mappings = {
      u = "scroll half-up";
      e = "scroll half-down";
      H = "toggle_page_mode";
      g = "zoom in";
      c = "zoom out";
      r = "reload";
      i = "recolor";
      p = "print";
      h = "scroll left";
      j = "scroll down";
      k = "scroll up";
      l = "scroll right";
      d = "follow";
      z = "quit";
      f = "goto 1";
      A = "adjust_window width";
      R = "rotate";
    };
  };

  xdg.mimeApps.defaultApplications = pkgs.aftixLib.registerMimes [
    {
      application = "zathura";
      mimetypes = [
        "application/pdf"
        "application/x-pdf"
        "application/epub"
      ];
    }
  ];
}
