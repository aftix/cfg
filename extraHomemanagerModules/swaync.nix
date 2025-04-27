# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
_: {
  services.swaync = {
    enable = true;

    settings = {
      timeout-low = 30;
      timeout = 60;
      widgets = [
        "inhibitors"
        "title"
        "dnd"
        "volume"
        "mpris"
        "notifications"
      ];
    };
  };
}
