{
  upkgs,
  config,
  lib,
  ...
}: {
  home = {
    # Packages for hypr tools and DE-lite features
    packages = with upkgs; [
      hyprlock
      hypridle
      hyprpaper
      hyprcursor
      xdg-desktop-portal-hyprland
      hyprland-protocols
      clipman
      pw-volume
      tofi
      slurp
      grim
      libnotify
      wl-clipboard
      xclip
      pinentry-gtk2
      pwvucontrol
      udiskie
    ];
    sessionVariables.XDG_CURRENT_DESKTOP = "Hyprland";
  };

  wayland.windowManager.hyprland = let
    terminal = "\"${upkgs.kitty}/bin/kitty\"";
    menu = "\"${upkgs.tofi}/bin/tofi-run\" | \"${upkgs.findutils}/bin/xargs\" \"${upkgs.hyprland}/bin/hyprctl\" dispatch exec";
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

    systemd.extraCommands = [
      "systemctl --user stop hyprland-session.target"
      "pkill waybar"
      "systemctl --user start hyprland-session.target"
    ];

    settings = {
      "$terminal" = "${terminal}";
      "$menu" = "${menu}";
      xwayland.force_zero_scaling = true;

      env = [
        "XCURSOR_SIZE,24"
        "QT_QPA_PLATFORMTHEME,qt5c"
        "HOME,${config.home.homeDirectory}"
        "HYPRCURSOR_THEME,rose-pine-hyprcursor"
      ];

      monitor = [
        "HDMI-A-1,1920x1080,2560x0,1"
        "DP-2,2560x1440,0x0,1"
        ",preferred,auto,1"
      ];

      input = {
        kb_layout = "us";
        kb_variant = "dvorak";
        kb_options = ["compose:prsc" "caps:escape"];
        numlock_by_default = true;

        repeat_rate = 60;
        repeat_delay = 300;

        follow_mouse = 1;

        touchpad.
        natural_scroll = false;

        sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
      };

      general = {
        gaps_in = 5;
        gaps_out = 20;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";

        layout = "dwindle";
        allow_tearing = false;
      };

      decoration = {
        rounding = 10;

        blur = {
          enabled = true;
          size = 3;
          passes = 1;

          vibrancy = 0.1696;
        };

        drop_shadow = true;
        shadow_range = 4;
        shadow_render_power = 3;
        "col.shadow" = "rgba(1a1a1aee)";
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

      master.new_is_master = true;
      gestures.workspace_swipe = false;
      misc.force_default_wallpaper = 0;

      windowrulev2 = [
        "tile,class:(kitty)"
        "suppressevent maximize, class:.*"
      ];

      "$mainMod" = "SUPER";

      bind =
        [
          # Window management keybinds
          "$mainMod ALT, Return, exec, $terminal"
          "$mainMod SHIFT, q, killactive,"
          "$mainMod, E, exec, loginctl lock-session"
          "$mainMod SHIFT, E, exit,"
          "$mainMod, Space, focuswindow, floating"
          "$mainMod, Tab, focuscurrentorlast,"
          "$mainMod ALT SHIFT, Space, focusurgentorlast,"
          "$mainMod SHIFT, Space, togglefloating,"
          "$mainMod, d, exec, $menu"
          "$mainMod, M, exec, hyprctl keyword general:layout \"master\""
          "$mainMod SHIFT, M, exec, hyprctl keyword general:layout \"dwindle\""
          "$mainMod SHIFT, T, togglegroup,"
          "$mainMod, T, changegroupactive, f"
          "$mainMod CTRL, T, changegroupactive, b"

          "$mainMod, Period, focusmonitor, +1"
          "$mainMod, Comma, focusmonitor, -1"
          "$mainMod SHIFT, Period, movewindow, mon:+1"
          "$mainMod SHIFT, Comma, movewindow, mon:-1"

          # Misc keybinds
          "$mainMod, P, exec, $HOME/.config/bin/passmenu"
          "$mainMod SHIFT, S, exec, $HOME/.config/bin/screenshot.sh"
          "$mainMod CTRL, S, exec, $HOME/.config/bin/screenshot.sh default copy"

          # Supmap binds
          "$mainMod ALT, T, submap, group"
          "$mainMod SHIFT, V, submap, volume"
          "$mainMod, r, submap, resize"
          "$mainMod SHIFT, P, submap, programs"

          # Scratch pad
          "$mainMod, Minus, togglespecialworkspace, magic"
          "$mainMod SHIFT, Minus, movetoworkspace, special:magic"
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
    };

    # Submaps must be done here for now
    extraConfig = builtins.concatStringsSep "\n" [
      "exec-once = hyprpaper"
      "exec-once = hypridle"
      (
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
            "SHIFT,w,exec,chromium"
            ",d,exec,discord"
            "SHIFT,d,exec,element-desktop"
          ];
        }
      )
    ];
  };

  # No home manager options for other tools yet
  xdg.configFile = let
    toCfgInner = tabstop: v: let
      stringer = x:
        if builtins.isBool x
        then
          if x
          then "true"
          else "false"
        else builtins.toString x;
    in
      lib.foldlAttrs (
        acc: name: value:
          if builtins.isAttrs value
          then ''
            ${acc}${tabstop}${name} {${toCfgInner "${tabstop}  " value}
            ${tabstop}}
          ''
          else if builtins.isList value
          then
            (
              builtins.concatStringsSep "\n" ([acc]
                ++ (map (
                    elem: (toCfgInner tabstop {"${name}" = elem;})
                  )
                  value))
            )
          else ''
            ${acc}
            ${tabstop}${name} = ${stringer value}''
      ) ""
      v;
    toCfg = toCfgInner "";
  in {
    "hypr/hypridle.conf".text = toCfg {
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

    "hypr/hyprlock.conf".text = toCfg {
      general = {
        ignore_empty_input = true;
        grace = 60;
      };

      background = {
        monitor = "";
        color = "rgba(25, 20, 20, 1.0)";
      };

      input-field = {
        monitor = "";
        size = "200, 50";
        outline_thickness = 3;
        dots_size = 0.33; # Scale of input-field height, 0.2 - 0.8
        dots_spacing = 0.15; # Scale of dots' absolute size, 0.0 - 1.0
        dots_center = false;
        dots_rounding = -1; # -1 default circle, -2 follow input-field rounding
        outer_color = "rgb(151515)";
        inner_color = "rgb(200, 200, 200)";
        font_color = "rgb(10, 10, 10)";
        fade_on_empty = true;
        fade_timeout = 1000; # Milliseconds before fade_on_empty is triggered.
        placeholder_text = "<i>Input Password...</i>"; # Text rendered in the input box when it's empty.
        hide_input = false;
        rounding = -1; # -1 means complete rounding (circle/oval)
        check_color = "rgb(204, 136, 34)";
        fail_color = "rgb(204, 34, 34)"; # if authentication failed, changes outer_color and fail message color";      	fail_text = <i>$FAIL <b>($ATTEMPTS)</b></i>; # can be set to empty
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
        color = "rgba(200, 200, 200, 1.0)";
        font_size = 25;
        font_family = "Noto Sans";

        position = "0, 80";
        halign = "center";
        valign = "center";
      };
    };

    "hypr/hyprpaper.conf".text = toCfg {
      preload = [
        "/home/aftix/.local/share/wallpaper/X0pSg4c.jpg"
        "/home/aftix/.local/share/wallpaper/dzLwX8H.jpg"
      ];

      wallpaper = [
        "DP-2,/home/aftix/.local/share/wallpaper/X0pSg4c.jpg"
        "HDMI-A-1,/home/aftix/.local/share/wallpaper/dzLwX8H.jpg"
      ];

      splash = true;
    };
  };
}
