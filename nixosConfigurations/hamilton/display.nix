# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2026 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  config,
  lib,
  pkgs,
  ...
}: {
  # GUI shell packages
  environment.systemPackages = with pkgs; [
    xdg-utils
    noctalia
    pw-volume
    libnotify
    wl-clipboard
    xclip
    xdotool
    pwvucontrol
    xwayland-satellite
  ];

  fonts.enableDefaultPackages = true;

  programs = {
    dconf.enable = true;
    niri.enable = true;
  };

  services = {
    # For noctalia shell
    tuned.enable = true;
    upower.enable = true;

    # Autologin as aftix user
    greetd.settings.initial_session = {
      command = lib.getExe config.programs.niri.package;
      user = lib.mkOverride 990 "aftix";
    };
  };

  # polkit for niri
  systemd.user.services.niri-polkit = {
    description = "PolicyKit Authentication Agent for niri";
    wantedBy = ["niri.service"];
    after = ["graphical-session.target"];
    partOf = ["graphical-session.target"];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  xdg = {
    autostart.enable = true;
    menus.enable = true;
    mime.enable = true;
    icons.enable = true;
  };

  # home-manager setup for niri/noctalia
  home-manager.sharedModules = [
    ({
      pkgs,
      config,
      ...
    }: {
      home.sessionVariables = {
        NIXOS_OZONE_WL = "1";
        XDG_SESSION_TYPE = "wayland";
        XCURSOR_SIZE = "32";
        XCURSOR_PATH = "/run/current-system/sw/share/icons:${config.xdg.dataHome}/icons";
        QT_QPA_PLATFORM = "wayland;xcb";
      };

      services.udiskie.enable = true;

      xdg.portal = {
        enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-gnome
          pkgs.xdg-desktop-portal-gtk
          pkgs.gnome-keyring
        ];
        configPackages = [
          pkgs.xdg-desktop-portal-gnome
          pkgs.xdg-desktop-portal-gtk
          pkgs.gnome-keyring
        ];
        config.preferred.default = "xdg-desktop-portal-gnome";
      };
    })
  ];
}
