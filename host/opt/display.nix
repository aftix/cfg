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
        _0xproto
        _3270
        agave
        anonymice
        arimo
        aurulent-sans-mono
        bigblue-terminal
        bitstream-vera-sans-mono
        blex-mono
        caskaydia-cove
        caskaydia-mono
        code-new-roman
        comic-shanns-mono
        commit-mono
        cousine
        d2coding
        daddy-time-mono
        dejavu-sans-mono
        departure-mono
        droid-sans-mono
        envy-code-r
        fantasque-sans-mono
        fira-code
        fira-mono
        geist-mono
        gohufont
        go-mono
        hack
        hasklug
        heavy-data
        hurmit
        im-writing
        inconsolata
        inconsolata-go
        inconsolata-lgc
        intone-mono
        iosevka
        iosevka-term
        iosevka-term-slab
        jetbrains-mono
        lekton
        liberation
        lilex
        martian-mono
        meslo-lg
        monaspace
        monofur
        monoid
        mononoki
        mplus
        noto
        open-dyslexic
        overpass
        profont
        proggy-clean-tt
        recursive-mono
        roboto-mono
        sauce-code-pro
        shure-tech-mono
        space-mono
        symbols-only
        terminess-ttf
        tinos
        ubuntu
        ubuntu-mono
        ubuntu-sans
        victor-mono
        zed-mono
      ]);
  };
}
