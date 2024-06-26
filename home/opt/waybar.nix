{pkgs, ...}: let
  waybar-dunst = final:
    final.writeShellApplication {
      name = "waybar-dunst";
      runtimeInputs = with final; [dunst gnugrep];
      text = ''
        COUNT="$(dunstctl count waiting)"
        ENABLED=""
        DISABLED=""
        if [ "$COUNT" != 0 ]; then
          DISABLED=" $COUNT"
        fi

        if dunstctl is-paused | grep -q "false" ; then
          echo '{"class": "", "text": " '"$ENABLED"' "}'
        else
          echo '{"class": "disabled", "text": " '"$DISABLED"' "}'
        fi
      '';
    };
  waybar-mullvad = final:
    final.writeShellApplication {
      name = "waybar-mullvad";
      text = ''
        if [ -d /proc/sys/net/ipv4/conf/wg0-mullvad ]; then
         echo '{"text": " 󰖂  ", "class": ""}'
        else
         echo '{"text": " 󰖂  ", "class": "disconnected"}'
        fi
      '';
    };
  waybar-backup = final:
    final.writeShellApplication {
      name = "waybar-backup";
      runtimeInputs = with final; [inotify-tools gnugrep];
      text = ''
        function active() {
          echo '{"text": "Backing up disk"}'
        }

        function offline() {
          echo '{}'
        }

        function wait() {
          inotifywait -m "$1" --include "$2" -e create -e delete 2>/dev/null
        }

        if [ -f /var/run/backupdisk.pid ]; then
          active
        else
          offline
        fi

        wait /var/run "backupdisk\\.pid" | while read -r line ; do
          grep -Fq '/var/run DELETE backupdisk.pid' <<< "$line" && offline
          grep -Fq '/var/run CREATE backupdisk.pid' <<< "$line" && active
        done
      '';
    };
in {
  nixpkgs.overlays = [
    (final: _: {
      waybar-dunst = waybar-dunst final;
      waybar-mullvad = waybar-mullvad final;
      waybar-backup = waybar-backup final;
    })
  ];
  home.packages = with pkgs; [waybar pkgs.waybar-dunst pkgs.waybar-mullvad pkgs.waybar-backup];

  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      target = "hyprland-session.target";
    };

    style =
      /*
      css
      */
      ''
        #disk,
        #temperature,
        #backlight,
        #network,
        #pulseaudio,
        #wireplumber,
        #custom-media,
        #tray,
        #mode,
        #idle_inhibitor,
        #power-profiles-daemon,
        #mpd {
          padding: 0 10px;
        }

        #window,
        #workspaces {
          margin: 0 4px;
        }

        .modules-left > widget:first-child > #workspaces {
          margin-left: 0;
        }

        #custom-mullvad,
        #custom-dunst {
          padding: 2px 2px;
          padding-right: 4px;
        }

        #custom-mullvad.disconnected,
        #network.disconnected,
        #custom-dunst.disabled,
        #mpd.disconnected {
          background-color: #f53c3c;
        }

        #mpd.stopped {
          background-color: #90b1b1;
        }

        #mpd.paused {
          background-color: #51a37a;
        }

        #idle_inhibitor.activated {
          background-color: #ecf0f1;
          color: black;
        }
      '';
  };

  xdg.configFile = let
    mullvad = "/run/current-system/sw/bin/mullvad";
    dunstctl = "${pkgs.dunst}/bin/dunstctl";
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
        exec = "${pkgs.waybar-backup}/bin/waybar-backup";
        restart-interval = 60;
        format = "{}";
        tooltip-format = "Backup status";
      };

      "custom/mullvad" = {
        return-type = "json";
        exec = "${pkgs.waybar-mullvad}/bin/waybar-mullvad";
        on-click = "if [ -e /proc/sys/net/ipv4/wg0-mullvad ]; then ${mullvad} disconnect ; else  ${mullvad} connect ; fi";
        interval = 1;
        tooltip-format = "VPN connection status";
      };

      "custom/dunst" = {
        return-type = "json";
        exec = "${pkgs.waybar-dunst}/bin/waybar-dunst";
        on-click = "\"${dunstctl}\" set-paused toggle";
        restart-interval = 1;
      };
    };
  in {
    "waybar/config.jsonc".source = (pkgs.formats.json {}).generate "waybar" [
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
            "custom/mullvad"
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
            "custom/mullvad"
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
  };
}
