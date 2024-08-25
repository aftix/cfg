{
  pkgs,
  lib,
  hyprPkgs,
  config,
  ...
}: let
  inherit (lib) mkDefault mkOverride mkForce;
  inherit (lib.options) mkOption;
in {
  options.my.greeterCfgExtra = mkOption {
    default = "";
    type = lib.types.str;
  };

  config = let
    wallpaper = "${hyprPkgs.hyprland}/share/hyprland/wall2.png";
  in {
    nix.settings = {
      substituters = [
        "https://hyprland.cachix.org"
        "https://nixpkgs-wayland.cachix.org"
      ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      ];
    };

    environment.systemPackages = with pkgs; [
      rose-pine-cursor
      hyprpaper
    ];

    programs = {
      hyprland = {
        enable = mkDefault true;
        package = hyprPkgs.hyprland;
      };

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
            command = "${hyprPkgs.hyprland}/bin/Hyprland";
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
                exec-once = ${config.programs.regreet.package}/bin/regreet; ${hyprPkgs.hyprland}/bin/hyprctl dispatch exit

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
                exec-once = ${pkgs.hyprpaper}/bin/hyprpaper --config ${paperCfg}

                ${config.my.greeterCfgExtra}
              '';
            };
          in {
            command = "${hyprPkgs.hyprland}/bin/Hyprland --config ${greetCfg}";
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

    fonts.packages = with pkgs; [
      inconsolata
      dejavu_fonts
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      dina-font
      proggyfonts
      nerdfonts
      font-awesome
      office-code-pro
      cantarell-fonts
    ];
  };
}
