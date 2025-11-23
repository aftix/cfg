# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkDefault mkForce;
  inherit (lib.options) mkOption;
in {
  options.aftix = {
    display-server = lib.mkEnableOption "enable display server configuration";

    greeterCfgExtra = mkOption {
      default = "";
      type = lib.types.str;
    };
  };

  config = let
    wallpaper = ../extraHomemanagerModules/wallpaper.jpg;
  in
    lib.mkIf config.aftix.display-server {
      environment.systemPackages = with pkgs; [
        rose-pine-cursor
      ];

      programs = {
        regreet = {
          enable = true;
          settings = {
            commands = {
              reboot = ["loginctl" "reboot"];
              poweroff = ["loginctl" "poweroff"];
            };

            GTK = {
              application_prefer_dark_theme = true;
              cursor_theme_name = mkForce "BreezeX-RosePine-Linux";
            };

            background = {
              path = wallpaper;
              fit = "Contain";
            };
          };
        };
      };

      console.useXkbConfig = true;

      services = {
        greetd = {
          enable = true;
          settings = {
            terminal.vt = 1;
            default_session.command = "${lib.getExe pkgs.cage} -s -mextend -- ${lib.getExe config.programs.regreet.package}";
          };
        };

        xserver.xkb = {
          layout = mkDefault "us";
          variant = mkDefault "dvorak";
          options = mkDefault "compose:prsc,caps:escape";
        };
      };

      fonts.packages =
        (with pkgs; [
          dejavu_fonts
          inconsolata
          material-icons
          noto-fonts
          noto-fonts-cjk-sans
          noto-fonts-cjk-serif
          noto-fonts-color-emoji
          liberation_ttf
          proggyfonts
          office-code-pro
          cantarell-fonts
          source-sans
          source-sans-pro
          source-han-mono
          source-han-sans
          source-han-serif
        ])
        ++ (with pkgs.nerd-fonts; [
          code-new-roman
          dejavu-sans-mono
          droid-sans-mono
          go-mono
          inconsolata
          inconsolata-go
          iosevka
          iosevka-term
          iosevka-term-slab
          jetbrains-mono
          liberation
          noto
          proggy-clean-tt
          roboto-mono
          symbols-only
          ubuntu
          ubuntu-mono
          ubuntu-sans
          victor-mono
          zed-mono
        ]);
    };
}
