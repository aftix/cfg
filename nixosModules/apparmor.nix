# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{pkgs, ...}: {
  environment = {
    systemPackages = with pkgs; [
      libapparmor
      apparmor-pam
      apparmor-utils
      apparmor-bin-utils
      apparmor-kernel-patches
      apparmor-profiles
      apparmor-parser
    ];
  };

  services.dbus.apparmor = "enabled";
  security.apparmor.enable = true;
}
