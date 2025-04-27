# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{config, ...}: {
  aftix.hyprland = let
    asus = "ASUSTek COMPUTER INC ASUS VG27W 0x0001995C";
    viewSonic = "ViewSonic Corporation VX2703 SERIES T8G132800478";
    inherit (config.aftix.hyprland) transforms;
  in {
    extraMonitor = [
      {
        desc = asus;
        position = "0x0";
      }
      {
        desc = viewSonic;
        position = "2560x-180";
        transform = transforms."90";
      }
    ];

    extraWorkspace = [
      {
        name = "1";
        options = [
          "persistent:true"
          "monitor:desc:${asus}"
          "default:true"
        ];
      }
      {
        name = "8";
        options = [
          "persistent:true"
          "monitor:desc:${asus}"
        ];
      }
      {
        name = "9";
        options = [
          "persistent:true"
          "monitor:desc:${asus}"
        ];
      }
      {
        name = "2";
        options = [
          "persistent:true"
          "monitor:desc:${viewSonic}"
          "default:true"
        ];
      }
      {
        name = "2";
        options = [
          "layoutopt:orientation:top"
        ];
      }
    ];
  };
}
