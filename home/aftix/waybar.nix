{
  upkgs,
  config,
  ...
}: {
  home.packages = with upkgs; [waybar];

  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      target = "hyprland-session.target";
    };
  };

  xdg.configFile = let
    waybarDir = "${config.home.homeDirectory}/.config/waybar";
    nord = "/run/current-system/sw/bin/nordvpn";
    dunstctl = "${upkgs.dunst}/bin/dunstctl";
    cfg = {
      layer = "top";
      position = "bottom";
      spacing = 4;

      "hyprland/workspaces" = {
        all-outputs = false;
        disable-scroll = true;
        warp-on-scroll = false;
        format = "{name}:{icon}";
        format-icons = {
          "1" = "";
          "2" = "";
          "3" = "";
          urgent = "";
          focused = "";
          default = "";
        };
      };

      keyboard-state = {
        numlock = true;
        capslock = false;
        format = "{name} {icon}";
        format-icons = {
          locked = "";
          unlocked = "";
        };
      };

      "hyprland/submap" = {
        format = "<span style=\"italic\">{}</span>";
        show-empty = false;
        tooltip = false;
      };

      idle_inhibitor = {
        format = "{icon}";
        format-icons = {
          activated = "";
          deactivated = "";
        };
      };

      tray = {
        spacing = 10;
      };

      clock = {
        timezone = "America/Chicago";
        format = "{:%H:%M %Y-%m-%d}";
        tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
      };

      cpu = {
        format = "{usage}% ";
        tooltip = false;
      };

      memory = {
        format = "{}% ";
      };

      temperature = {
        critical-threshold = 80;
        format = "{temperatureC}°C {icon}";
        format-icons = ["" "" ""];
      };

      pulseaudio = {
        format = "{volume}% {icon} {format_source}";
        format-bluetooth = "{volume}% {icon} {format_source}";
        format-bluetooth-muted = " {icon} {format_source}";
        format-muted = " {format_source}";
        format-source = "{volume}% ";
        format-source-muted = "";
        format-icons = {
          headphone = "";
          hands-free = "";
          headset = "";
          phone = "";
          portable = "";
          car = "";
          default = ["" "" ""];
        };
        on-click = "pwvucontrol";
      };

      "custom/backup" = {
        return-type = "json";
        exec = "${waybarDir}/watchfile.sh";
        restart-interval = 60;
        format = "{}";
        tooltip-format = "Backup status";
      };

      "custom/nordvpn" = {
        return-type = "json";
        exec = "${waybarDir}/nordvpn.sh";
        on-click = "[ -e /proc/sys/net/ipv4/nordlynx ] && \"${nord}\" d || \"${nord}\" c";
        interval = 5;
        tooltip-format = "VPN connection status";
      };

      "custom/dunst" = {
        return-type = "json";
        exec = "${waybarDir}/dunst.sh";
        on-click = "\"${dunstctl}\" set-paused toggle";
        restart-interval = 1;
      };
    };
  in {
    "waybar/config.jsonc".source = (upkgs.formats.json {}).generate "waybar" [
      (cfg
        // {
          # machine-specific, can not be factored out into machine.nix
          output = "DP-1";

          modules-left = [
            "hyprland/workspaces"
            "hyprland/submap"
            "custom/backup"
          ];

          modules-center = [
            "hyprland/window"
          ];

          modules-right = [
            "mpd"
            "idle_inhibitor"
            "pulseaudio"
            "custom/nordvpn"
            "network"
            "cpu"
            "memory"
            "temperature"
            "keyboard-state"
            "clock"
            "custom/dunst"
            "tray"
          ];

          network = {
            format-wifi = "{essid} ({signalStrength}%) ";
            format-ethernet = "{ipaddr}/{cidr} ";
            tooltip-format = "{ifname} via {gwaddr} ";
            format-linked = "{ifname} (No IP) ";
            format-disconnected = "Disconnected ⚠";
            format-alt = "{ifname} = {ipaddr}/{cidr}";
          };

          mpd = {
            format = "{stateIcon} {consumeIcon}{randomIcon}{repeatIcon}{singleIcon}{artist} - {album} - {title} ({elapsedTime:%M:%S}/{totalTime:%M:%S}) ⸨{songPosition}|{queueLength}⸩ {volume}% ";
            format-disconnected = "Disconnected ";
            format-stopped = "{consumeIcon}{randomIcon}{repeatIcon}{singleIcon}Stopped ";
            unknown-tag = "N/A";
            interval = 5;
            consume-icons = {
              "on" = " ";
            };
            random-icons = {
              off = "<span color=\"#f53c3c\"></span> ";
              on = " ";
            };
            repeat-icons = {
              on = " ";
            };
            single-icons = {
              on = "1 ";
            };
            state-icons = {
              paused = "";
              playing = "";
            };
            tooltip-format = "MPD (connected)";
            tooltip-format-disconnected = "MPD (disconnected)";
          };
        })
      (cfg
        // {
          # machine-specific, can not be factored out into machine.nix
          output = "DP-2";

          modules-left = [
            "hyprland/workspaces"
            "hyprland/submap"
            "custom/backup"
          ];

          modules-center = [
            "hyprland/window"
          ];

          modules-right = [
            "idle_inhibitor"
            "pulseaudio"
            "custom/nordvpn"
            "cpu"
            "memory"
            "temperature"
            "keyboard-state"
            "clock"
            "custom/dunst"
            "tray"
          ];
        })
    ];

    "waybar/watchfile.sh" = {
      executable = true;
      text = ''
        #!${upkgs.bash}/bin/bash

        function active() {
          "${upkgs.coreutils}/bin/echo" '{"text": "Backing up disk"}'
        }

        function offline() {
          "${upkgs.coreutils}/bin/echo" '{}'
        }

        function wait() {
          "${upkgs.inotify-tools}/bin/inotifyway" -m "$1" --include "$2" -e create -e delete 2>/dev/null
        }

        [ -f /var/run/backupdisk.pid ] && echo
        wait /var/run "backupdisk\\.pid" | while read -r line ; do
          "${upkgs.gnugrep}/bin/grep" -Fq '/var/run DELETE backupdisk.pid' <<< "$line" && offline
          "${upkgs.gnugrep}/bin/grep" -Fq '/var/run CREATE backupdisk.pid' <<< "$line" && active
        done
      '';
    };

    "waybar/dunst.sh" = {
      executable = true;
      text = ''
        #!${upkgs.bash}/bin/bash

        DUNSTCTL="${upkgs.dunst}/bin/dunstctl" GREP="${upkgs.gnugrep}/bin/grep"

        COUNT="$("$DUNSTCTL" count waiting)"
        ENABLED=""
        DISABLED=""
        if [ "$COUNT" != 0 ]; then
          DISABLED=" $COUNT"
        fi

        if "$DUNSTCTL" is-paused | "$GREP" -q "false" ; then
          echo '{"class": "", "text": " '"$ENABLED"' "}'
        else
          echo '{"class": "disabled", "text": " '"$DISABLED"' "}'
        fi
      '';
    };

    "waybar/nordvpn.sh" = {
      executable = true;
      text = ''
        #!${upkgs.bash}/bin/bash

        if [ -d /proc/sys/net/ipv4/conf/nordlynx ]; then
         echo '{"text": " 󰖂  ", "class": ""}'
        else
         echo '{"text": " 󰖂  ", "class": "disconnected"}'
        fi
      '';
    };

    # Don't need to put the big CSS file in here
    "waybar/style.css".source = ./_external/waybar/style.css;
  };
}
