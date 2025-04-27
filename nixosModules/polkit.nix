# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
# Add some groups for various system management actions
{
  security.polkit = {
    enable = true;
    extraConfig =
      /*
      javascript
      */
      ''
        polkit.addRule(function(action, subject) {
          if ([
            "org.freedesktop.login1.inhibit-block-sleep",
            "org.freedesktop.login1.inhibit-block-shutdown",
            "org.freedesktop.login1.inhibit-block-idle",
          ].indexOf(action.id) !== -1 && subject.isInGroup("idle-inhibit")) {
            return polkit.Result.YES;
          }
        })

        polkit.addRule(function(action, subject) {
          if (action.id === "org.freedesktop.systemd1.manage-units" && subject.isInGroup("manage-units")) {
            return polkit.Result.YES;
          }
        })

        polkit.addRule(function(action, subject) {
          if ([
            "org.freedesktop.login1.reboot",
            "org.freedesktop.login1.reboot-multiple-sessions",
            "org.freedesktop.login1.power-off",
            "org.freedesktop.login1.power-off-multiple-sessions",
            "org.freedesktop.login1.hibernate",
            "org.freedesktop.login1.hibernate-multiple-sessions",
            "org.freedesktop.login1.suspend",
            "org.freedesktop.login1.suspend-multiple-sessions",
          ].indexOf(action.id) !== -1 && subject.isInGroup("power-management")) {
            return polkit.Result.YES;
          }
        })

        polkit.addRule(function(action, subject) {
          if (action.id === "org.freedesktop.login1.lock-sessions" && subject.isInGroup("lock-sessions")) {
            return polkit.Result.YES;
          }
        })
      '';
  };

  users.groups = {
    idle-inhibit = {};
    manage-units = {};
    power-management = {};
    lock-sessions = {};
  };
}
