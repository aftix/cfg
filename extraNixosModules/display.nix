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
        noto-fonts-cjk-serif
        noto-fonts-emoji
        noto-fonts-color-emoji
        liberation_ttf
        proggyfonts
        office-code-pro
        cantarell-fonts
        source-sans
        source-sans-pro
        source-han-mono
        source-han-sans
        source-han-sans-japanese
        source-han-serif
        source-han-serif-japanese
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
