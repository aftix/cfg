{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkDefault mkOverride mkForce;
  inherit (lib.options) mkOption;

  inherit (config.dep-inject) inputs;
  hyprlandPkg = config.programs.hyprland.package;
in {
  options.my.greeterCfgExtra = mkOption {
    default = "";
    type = lib.types.str;
  };

  config = let
    wallpaper = "${inputs.hyprland}/share/hyprland/wall2.png";
  in {
    environment.systemPackages = with pkgs; [
      rose-pine-cursor
      hyprpaper
    ];

    programs = {
      hyprland.enable = mkDefault true;

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

          initial_session = {
            command = "${hyprlandPkg}/bin/Hyprland";
            user = mkOverride 990 "aftix";
          };

          default_session = let
            paperCfg = pkgs.writeTextFile {
              name = "hyprpaper-cfg";
              text = ''
                preload = ${wallpaper}
                splash = false
                ipc = off
                wallpaper = ,${wallpaper}
              '';
            };

            greetCfg = pkgs.writeTextFile {
              name = "greetd-cfg";
              text = ''
                exec-once = ${config.programs.regreet.package}/bin/regreet; ${hyprlandPkg}/bin/hyprctl dispatch exit

                monitor=,preferred,auto,1
                input {
                  touchpad {
                    natural_scroll=false
                  }
                  kb_layout=us
                  kb_options=compose:prsc
                  kb_options=caps:escape
                  kb_variant=dvorak
                  numlock_by_default=true
                  repeat_delay=300
                  repeat_rate=60
                  sensitivity=0
                }
                misc {
                  force_default_wallpaper=0
                }
                exec-once = ${lib.getExe pkgs.hyprpaper} --config ${paperCfg}

                ${config.my.greeterCfgExtra}
              '';
            };
          in {
            command = "${hyprlandPkg}/bin/Hyprland --config ${greetCfg}";
            user = mkOverride 990 "aftix";
          };
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
        noto-fonts-emoji
        liberation_ttf
        dina-font
        proggyfonts
        office-code-pro
        cantarell-fonts
      ])
      ++ (with pkgs.nerd-fonts; [
        dejavu-sans-mono
        droid-sans-mono
        fira-code
        fira-mono
        inconsolata
        liberation
        noto
        symbols-only
      ]);
  };
}
