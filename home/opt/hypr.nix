{
  pkgs,
  config,
  lib,
  hyprPkgs,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib.strings) optionalString concatMapStringsSep escapeShellArg;
  inherit (config.my.lib) toHyprMonitors toHyprWorkspaces toHyprCfg;
  cfg = config.my.hyprland;
in {
  imports = [./waybar.nix];

  options.my.hyprland = with lib.types; {
    extraMonitor = mkOption {
      default = [];
      # type = listOf (attrsOf {
      #   desc = nullOr str;
      #   mode = nullOr str;
      #   position = nullOr str;
      #   transform = nullOr str;
      #   scale = nullOr str;
      # });
      description = ''
        Add to the hyprland monitor settings
      '';
    };

    extraWorkspace = mkOption {
      default = [];
      # type = listOf (attrsOf {
      #   name = str;
      #   options = listOf str;
      # });
      description = ''
        Add to the hyprland workspace settings
      '';
    };

    transforms = mkOption {
      type = uniq attrs;
      readOnly = true;
    };
  };

  config = {
    nixpkgs.overlays = [
      (final: _: {
        screenshot = final.writeShellApplication {
          name = "screenshot";
          runtimeInputs = with final; [wl-clipboard grim slurp libnotify tofi systemd satty];
          text = ''
            shopt -s globstar nullglob
            # shellcheck source=/dev/null
            source <(systemctl --user show-environment | grep -v PATH=)

            grim -g "$(slurp -o -r -c '#ff0000ff')" - | \
            satty --filename - --fullscreen --output-filename ~/media/screenshots/satty-"$(date '+%Y%m%d-%H:%M:%S')".png \
            --early-exit --initial-tool crop --copy-command wl-copy
          '';
        };

        zenith-popup = final.writeShellApplication {
          name = "zenith-popup";
          runtimeInputs = with final; [zenith];
          text = ''
            [ -n "$1" ] && "$1" -e ${escapeShellArg final.zenith}/bin/zenith
          '';
        };
      })
    ];

    my = {
      hyprland.transforms = {
        normal = "0";
        "90" = "1";
        "180" = "2";
        "270" = "3";
        flipped = "4";
        "flipped-90" = "5";
        "flipped-180" = "6";
        "flipped-270" = "7";
      };

      lib = {
        toHyprMonitors = builtins.map (
          {
            desc ? "",
            mode ? "preferred",
            position ? "auto",
            scale ? "1",
            transform ? "",
          }: let
            description =
              optionalString (desc != "") "desc:" + desc;
            orientation =
              optionalString (transform != "")
              ",transform,"
              + transform;
          in "${description},${mode},${position},${scale}${orientation}"
        );

        toHyprWorkspaces = builtins.map ({
          name,
          options,
        }:
          builtins.concatStringsSep "," ([name] ++ options));

        toHyprCfg = let
          inherit (config.my.lib) stringify;
          toCfgInner = tabstop: v:
            lib.foldlAttrs (
              acc: name: value:
                if builtins.isAttrs value
                then ''
                  ${acc}${tabstop}${name} {${toCfgInner "${tabstop}  " value}
                  ${tabstop}}
                ''
                else if builtins.isList value
                then
                  acc
                  + (
                    concatMapStringsSep "" (
                      elem: (toCfgInner tabstop {"${name}" = elem;})
                    )
                    value
                  )
                else ''
                  ${acc}
                  ${tabstop}${name} = ${stringify value}''
            ) ""
            v;
        in
          toCfgInner "";
      };
    };

    home = {
      # Packages for hypr tools and DE-lite features
      packages = with pkgs; [
        hyprcursor
        hyprlock
        hypridle
        hyprpaper

        pw-volume
        libnotify
        wl-clipboard
        xclip
        xdotool
        kdePackages.polkit-kde-agent-1
        pwvucontrol
        keepassxc

        screenshot
        zenith-popup
      ];

      sessionVariables = {
        XDG_CURRENT_DESKTOP = "Hyprland";
        NIXOS_OZONE_WL = "1";
      };
    };

    fonts.fontconfig.enable = true;

    programs.tofi = {
      enable = true;
      settings = {
        width = 900;
        height = 300;
        border-width = 6;
        corner-radius = 10;
        require-match = false;
        auto-accept-single = true;
      };
    };

    services = {
      clipman.enable = true;
      udiskie.enable = true;
    };

    wayland.windowManager.hyprland = let
      terminal = "\"${pkgs.kitty}/bin/kitty\"";
      menu = "\"${pkgs.tofi}/bin/tofi-run\" | \"${pkgs.findutils}/bin/xargs\" \"${pkgs.hyprland}/bin/hyprctl\" dispatch exec";
      left = "h";
      right = "l";
      up = "k";
      down = "j";
      dirMapDefault = {
        left = "l";
        right = "r";
        up = "u";
        down = "d";
      };
      mkMovements = dirMap: keyMods: dispatch: [
        "${keyMods},left,${dispatch},${builtins.getAttr "left" (dirMapDefault // dirMap)}"
        "${keyMods},${left},${dispatch},${builtins.getAttr "left" (dirMapDefault // dirMap)}"

        "${keyMods},right,${dispatch},${builtins.getAttr "right" (dirMapDefault // dirMap)}"
        "${keyMods},${right},${dispatch},${builtins.getAttr "right" (dirMapDefault // dirMap)}"

        "${keyMods},up,${dispatch},${builtins.getAttr "up" (dirMapDefault // dirMap)}"
        "${keyMods},${up},${dispatch},${builtins.getAttr "up" (dirMapDefault // dirMap)}"

        "${keyMods},down,${dispatch},${builtins.getAttr "down" (dirMapDefault // dirMap)}"
        "${keyMods},${down},${dispatch},${builtins.getAttr "down" (dirMapDefault // dirMap)}"
      ];
      mkSubmaps = maps:
        builtins.concatStringsSep "\n"
        (
          builtins.attrValues
          (
            builtins.mapAttrs (name: binds: (builtins.concatStringsSep "\n" (
              ["submap = ${name}"]
              ++ binds
              ++ [
                "bind = ,Escape,submap,reset"
                "bind = ,Return,submap,reset"
                "submap = reset"
                ""
              ]
            )))
            maps
          )
        );
    in {
      enable = true;
      xwayland.enable = true;
      systemd.enable = true;

      package = hyprPkgs.hyprland;
      plugins = with hyprPkgs; [
        hyprbars
        hyprexpo
      ];

      settings = {
        "$terminal" = "${terminal}";
        "$menu" = "${menu}";
        xwayland.force_zero_scaling = true;

        env = [
          "XCURSOR_SIZE,32"
          "XCURSOR_PATH,/run/current-system/sw/share/icons:${config.xdg.dataHome}/icons"
          "QT_QPA_PLATFORM,wayland;xcb"
          "QT_QPA_PLATFORMTHEME,qt5c"
          "HOME,${config.home.homeDirectory}"
          "HYPRCURSOR_THEME,rose-pine-hyprcursor"
        ];

        input = {
          kb_layout = "us";
          kb_variant = "dvorak";
          kb_options = ["compose:prsc" "caps:escape"];
          numlock_by_default = true;

          repeat_rate = 60;
          repeat_delay = 300;

          follow_mouse = 1;

          touchpad.natural_scroll = false;

          sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
        };

        general = {
          gaps_in = 5;
          gaps_out = 20;
          border_size = 2;

          layout = "master";
          allow_tearing = false;
        };

        decoration = {
          rounding = 10;

          blur = {
            enabled = true;
            size = 3;
            passes = 1;
            xray = true;

            vibrancy = 0.1696;
          };

          drop_shadow = true;
          shadow_range = 4;
          shadow_render_power = 3;
        };

        animations = {
          enabled = true;
          bezier = ["myBezier, 0.05, 0.9, 0.1, 1.05"];
          animation = [
            " windows, 1, 7, myBezier"
            " windowsOut, 1, 7, default, popin 80%"
            " border, 1, 10, default"
            " borderangle, 1, 8, default"
            " fade, 1, 7, default"
            " workspaces, 1, 6, default"
          ];
        };

        dwindle = {
          pseudotile = true;
          preserve_split = true;
        };

        plugin.hyprbars = {
          bar_height = 20;
          hyprbars-button = [
            "rgb(ff4040), 10, 󰖭, hyprctl dispatch killactive"
            "rgb(eeee11), 10, , hyprctl dispatch fullscreen 1"
          ];
        };

        master.new_is_master = true;
        gestures.workspace_swipe = false;
        misc.force_default_wallpaper = 0;

        "$mainMod" = "SUPER";

        bind =
          [
            # Window management keybinds
            "$mainMod ALT, Return, exec, $terminal"
            "$mainMod SHIFT, q, killactive,"
            "$mainMod, E, exec, loginctl lock-session"
            "$mainMod CTRL, E, exec,hyprctl reload"
            "$mainMod SHIFT, E, exit,"
            "$mainMod, Space, focuswindow, floating"
            "$mainMod, Tab, focuscurrentorlast,"
            "$mainMod ALT SHIFT, Space, focusurgentorlast,"
            "$mainMod SHIFT, Space, togglefloating,"
            "$mainMod, d, exec, $menu"
            "$mainMod, M, exec, hyprctl keyword general:layout \"master\""
            "$mainMod CTRL, M, layoutmsg, orientationnext"
            "$mainMod SHIFT, M, exec, hyprctl keyword general:layout \"dwindle\""
            "$mainMod SHIFT, T, togglegroup,"
            "$mainMod, T, changegroupactive, f"
            "$mainMod CTRL, T, changegroupactive, b"

            "$mainMod, Period, focusmonitor, +1"
            "$mainMod, Comma, focusmonitor, -1"
            "$mainMod SHIFT, Period, movewindow, mon:+1"
            "$mainMod SHIFT, Comma, movewindow, mon:-1"

            "$mainMod, BracketRight, layoutmsg, cyclenext"
            "$mainMod, BracketLeft, layoutmsg, cycleprev"
            "$mainMod SHIFT, BracketRight, layoutmsg, swapnext"
            "$mainMod SHIFT, BracketLeft, layoutmsg, swapprev"
            "$mainMod CTRL, BracketRight, layoutmsg, rollnext"
            "$mainMod CTRL, BracketLeft, layoutmsg, rollprev"
            "$mainMod CTRL, Period, layoutmsg, swapwithmaster"
            "$mainMod ALT, Period, layoutmsg, focusmaster"

            # Plugin binds
            "$mainMod, grave, hyprexpo:expo, toggle"

            # Misc keybinds
            "$mainMod, P, exec, keepassxc"
            "$mainMod, S, exec, ${pkgs.screenshot}/bin/screenshot"
            "$mainMod SHIFT, S, exec, [float;group barred deny] ${pkgs.zenith-popup}/bin/zenith-popup $terminal"
            "$mainMod, C, exec, ${pkgs.clipman}/bin/clipman pick --tool CUSTOM -T ${pkgs.tofi}/bin/tofi"
            "$mainMod SHIFT, C, exec, ${pkgs.clipman}/bin/clipman clear --tool CUSTOM -T \"${pkgs.tofi}/bin/tofi --auto-accept-single=false\""

            # Supmap binds
            "$mainMod ALT, T, submap, group"
            "$mainMod SHIFT, V, submap, volume"
            "$mainMod, r, submap, resize"
            "$mainMod SHIFT, P, submap, programs"

            # Scratch pad
            "$mainMod, Minus, togglespecialworkspace, magic"
            "$mainMod SHIFT, Minus, movetoworkspace, special:magic"

            # Dunst hotkeys
            "CTRL, Space, exec, dunstctl close"
            "CTRL SHIFT, Space, exec, dunstctl close-all"
            "CTRL SHIFT, Period, exec, dunstctl context"
            "CTRL SHIFT, Grave, exec, dunstctl history-pop"
          ]
          ++
          # Focus movement
          (mkMovements {} "$mainMod" "moveFocus")
          ++
          # Window movement
          (mkMovements {} "$mainMod SHIFT" "movewindow")
          ++
          # Workspace controls
          builtins.concatLists (builtins.genList (
              y: let
                x = builtins.toString y;
              in [
                "$mainMod, ${x}, workspace, ${x}"
                "$mainMod SHIFT, ${x}, movetoworkspace, ${x}"
                "$mainMod CTRL SHIFT, ${x}, movetoworkspacesilent, ${x}"
              ]
            )
            10);

        bindel = [
          ",XF86AudioRaiseVolume,exec,pw-volume change +1%"
          ",XF86AudioLowerVolume,exec,pw-volume change -1%"
        ];

        bindl = [
          ",XF86AudioMute,exec,pw-volume mute toggle"
          ",XF86AudioPlay,exec,mpc toggle"
          ",XF86AudioPause,exec,mpc pause"
          ",XF86AudioNext,exec,mpc next"
          ",XF86AudioPrev,exec,mpc prev"
        ];

        # Mouse binds
        bindm = [
          "$mainMod, mouse:272, movewindow"
          "$mainMod, mouse:273, resizewindow"
        ];

        exec-once = [
          "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1"
          "hyprpaper"
          "hypridle"
          "[workspace 1 silent] firefox"
          "[workspace 8 silent] thunderbird"
          "[workspace 9 silent] keepassxc"
          "[workspace 2;group new] $terminal --title irc --session \"$HOME/.config/kitty/irc.session\""
          "[workspace 2;group set] element-desktop"
          "[workspace 2] discord"
        ];

        windowrulev2 = [
          "tile,class:(kitty)"

          "suppressevent maximize, class:.*"

          "stayfocused, class:^(Pinentry-)"
          "float, class:^(Pinentry-)"
          "noborder, class:^(Pinentry-)"
          "group barred deny, class:^(Pinentry-)"

          "idleinhibit focus, class:(mpv)"

          "group set, class:^(Discord)"

          "plugin:hyprbars:nobar, floating:0"

          "tag +filepicker, initialTitle:^(blob:.+)$"
          "tag +filepicker, initialTitle:^(Save [A-Z][^ ]*)$"
          "tag +filepicker, initialTitle:^(Open [A-Z][^ ]*)$"

          "float, tag:filepicker"
          "group barred deny, tag:filepicker"

          "tag +thunderbirdpopup, initialTitle:^(Activity Manager)$"
          "tag +thunderbirdpopup, initialTitle:^(About .+Thunderbird)$"

          "float, tag:thunderbirdpopup"
          "group barred deny, tag:thunderbirdpopup"
        ];

        workspace =
          [
            "special:scratchpad, on-created-empty:$terminal"
          ]
          ++ toHyprWorkspaces cfg.extraWorkspace;

        monitor =
          [
            ",preferred,auto,1"
          ]
          ++ toHyprMonitors cfg.extraMonitor;

        exec = [
          "systemctl --user stop hyprland-session.target ; pkill waybar ; systemctl --user start hyprland-session.target"
        ];
      };

      # Submaps must be done here for now
      extraConfig =
        mkSubmaps
        {
          group =
            [
              "bindel = ,Comma,movegroupwindow,b"
              "bindel = ,Period,movegroupwindow,f"
            ]
            ++ (map (cmd: "bindel = ${cmd}") (mkMovements {} "" "moveintogroup"));
          volume =
            [
              "bindel=SHIFT, m, exec, pw-volume mute off"
              "bindel=SHIFT, u, exec, pw-volume change +10%"
              "bindel=SHIFT, d, exec, pw-volume change -10%"
            ]
            ++ (map (cmd: "bindel=, ${cmd}") [
              "XF86AudioRaiseVolume, exec, pw-volume change +1%"
              "XF86AudioLowerVolume, exec, pw-volume change -1%"
              "u, exec, pw-volume change +3%"
              "d, exec, pw-volume change -3%"
              "m, exec, pw-volume mute on"
            ])
            ++ (map (cmd: "bindl=, ${cmd}") [
              "XF86AudioMute, exec, pw-volume mute toggle"
              "XF86AudioPlay, exec, mpc toggle"
              "XF86AudioPause, exec, mpc pause"
              "XF86AudioNext, exec, mpc next"
              "XF86AudioPrev, exec, mpc prev"
              "t, exec, pw-volume mute toggle"
            ]);
          resize = map (cmd: "binde=${cmd}") (mkMovements {
            left = "-10 0";
            right = "10 0";
            up = "0 -10";
            down = "0 10";
          } "" "resizeactive");
          programs = map (cmd: "bind = ${cmd}") [
            ",w,exec,firefox"
            ",e,exec,thunderbird"
            "SHIFT,w,exec,chromium"
            ",d,exec,discord"
            "SHIFT,d,exec,element-desktop"
          ];
        };
    };

    xdg = {
      portal = {
        enable = true;
        extraPortals = [pkgs.xdg-desktop-portal-hyprland];
        configPackages = [pkgs.xdg-desktop-portal-hyprland];
        config.preferred.default = "xdg-desktop-portal-hyprland";
      };

      # No home manager options for other tools yet
      configFile = {
        "hypr/wallpaper.jpg".source = ./wallpaper.jpg;

        "hypr/hypridle.conf".text = toHyprCfg {
          general = {
            lock_cmd = "pidof hyprlock || hyprlock";
            before_sleep_cmd = "loginctl lock-session";
            after_sleep_cmd = "hyprctl dispatch dpms on";
          };

          listener = [
            {
              timeout = 600;
              on-timeout = "loginctl lock-session";
            }
            {
              timeout = 660;
              on-timeout = "systemctl suspend";
            }
            {
              timeout = 1800;
              on-timeout = "systemctl suspend";
            }
          ];
        };

        "hypr/hyprlock.conf".text = toHyprCfg {
          general = {
            ignore_empty_input = true;
            grace = 60;
          };

          background = {
            monitor = "";
          };

          input-field = {
            monitor = "";
            size = "200, 50";
            outline_thickness = 3;
            dots_size = 0.33; # Scale of input-field height, 0.2 - 0.8
            dots_spacing = 0.15; # Scale of dots' absolute size, 0.0 - 1.0
            dots_center = false;
            dots_rounding = -1; # -1 default circle, -2 follow input-field rounding
            fade_on_empty = true;
            fade_timeout = 1000; # Milliseconds before fade_on_empty is triggered.
            placeholder_text = "<i>Input Password...</i>"; # Text rendered in the input box when it's empty.
            hide_input = false;
            rounding = -1; # -1 means complete rounding (circle/oval)
            fail_transition = 300; # transition time in ms between normal outer_color and fail_color
            capslock_color = -1;
            numlock_color = -1;
            bothlock_color = -1; # when both locks are active. -1 means don't change outer color (same for above)
            invert_numlock = false; # change color if numlock is off

            position = "0, -20";
            halign = "center";
            valign = "center";
          };

          label = {
            monitor = "";
            text = "$USER";
            font_size = 25;
            font_family = "Noto Sans";

            position = "0, 80";
            halign = "center";
            valign = "center";
          };
        };

        "hypr/hyprpaper.conf".text = toHyprCfg {
          preload = [
            "/home/aftix/.config/hypr/wallpaper.jpg"
          ];

          wallpaper = [
            ",/home/aftix/.config/hypr/wallpaper.jpg"
          ];

          splash = true;
        };

        # Fontconfig
        "fontconfig/fonts.conf".text =
          /*
          xml
          */
          ''
            <?xml version="1.0"?>
            <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
            <fontconfig>
            <match target="pattern">
              <test qual="any" name="family"><string>serif</string></test>
              <edit name="family" mode="assign" binding="same"><string>Source Han Serif JP</string></edit>
            </match>
            <match target="pattern">
              <test qual="any" name="family"><string>sans-serif</string></test>
              <edit name="family" mode="assign" binding="same"><string>Source Han Sans JP</string></edit>
            </match>
            <match target="pattern">
              <test qual="any" name="family"><string>monospace</string></test>
              <edit name="family" mode="assign" binding="same"><string>WenQuanYi Zen Hei Mono</string></edit>
            </match>
            </fontconfig>
          '';
      };
    };
  };
}
