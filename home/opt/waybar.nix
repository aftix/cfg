{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.lists) optionals;
  inherit (lib.strings) optionalString;

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
    (final: _:
      {
        waybar-dunst = waybar-dunst final;
        waybar-mullvad = waybar-mullvad final;
        waybar-backup = waybar-backup final;
      }
      // optionalAttrs config.services.dunst.enable {waybar-dunst = waybar-dunst final;})
  ];
  home.packages = with pkgs; [waybar pkgs.waybar-dunst pkgs.waybar-mullvad pkgs.waybar-backup] ++ optionals config.services.dunst.enable [pkgs.dunst];

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
        #custom-notification {
          padding: 2px 2px;
          padding-right: 4px;
        }

        #custom-mullvad.disconnected,
        #network.disconnected,
        #custom-notification.disabled,
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
      ''
      + optionalString config.services.swaync.enable ''
        #custom-notification {
          font-family: "NotoSansMono Nerd Font";
        }
      '';
  };

  xdg.configFile = let
    mullvad = "/run/current-system/sw/bin/mullvad";

    dunstNotification = {
      return-type = "json";
      exec = lib.getExe pkgs.waybar-dunst;
      on-click = "${lib.getExe' config.services.dunst.package "dunstctl"} set-paused toggle";
      restart-interval = 1;
    };

    swayncNotification = let
      swaync = lib.getExe' config.services.swaync.package "swaync-client";
    in {
      tooltip = false;
      format = "{} {icon}";
      format-icons = {
        notification = "<span foreground='red'><sup></sup></span>";
        none = "";
        dnd-notification = "<span foreground='red'><sup></sup></span>";
        dnd-none = "";
        inhibited-notification = "<span foreground='red'><sup></sup></span>";
        inhibited-none = "";
        dnd-inhibited-notification = "<span foreground='red'><sup></sup></span>";
        dnd-inhibited-none = "";
      };
      return-type = "json";
      exec-if = "which ${swaync}";
      exec = "${swaync} -swb";
      on-click = "${swaync} -t -sw";
      on-click-right = "${swaync} -d -sw";
      escape = true;
    };

    customNotification = assert config.services.dunst.enable != config.services.swaync.enable;
      if config.services.swaync.enable
      then swayncNotification
      else dunstNotification;

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

      "custom/notification" = customNotification;
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
            "custom/notification"
            "network"
            "cpu"
            "memory"
            "temperature"
            "keyboard-state"
            "clock"
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
            "tray"
          ];
        })
    ];
  };

  systemd.user.services.waybar.Service = {
    CapabilityBoundingSet = lib.strings.concatStringsSep " " (builtins.map (s: "~CAP_" + s) [
      "BPF"
      "BLOCK_SUSPEND"
      "CHOWN"
      "FOWNER"
      "FSETID"
      "IPC_OWNER"
      "LEASE"
      "LINUX_IMMUTABLE"
      "NET_ADMIN"
      "NET_BIND_SERVICE"
      "NET_BROADCAST"
      "NET_RAW"
      "SETFCAP"
      "SETGID"
      "SETPCAP"
      "SETUID"
      "SYS_ADMIN"
      "SYS_BOOT"
      "SYS_CHROOT"
      "SYS_MODULE"
      "SYS_NICE"
      "SYS_PACCT"
      "SYS_PTRACE"
      "SYS_RAWIO"
      "SYS_RESOURCE"
      "SYS_SYSLOG"
      "SYS_TIME"
      "SYS_TTY_CONFIG"
    ]);
    DeviceAllow = "";
    IPAddressDeny = "any";
    KeyringMode = "shared";
    LockPersonality = true;
    MemoryDenyWriteExecute = true;
    NoNewPrivileges = true;
    PrivateDevices = true;
    PrivateMounts = true;
    PrivateTmp = true;
    PrivateUsers = true;
    ProcSubset = "pid";
    ProtectClock = true;
    ProtectControlGroups = true;
    ProtectHostname = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    ProtectProc = "invisible";
    ProtectSystem = true;
    ReadOnlyPaths = "/home";
    RestrictAddressFamilies = "AF_UNIX AF_INET";
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    SystemCallArchitectures = "native";
    SystemCallFilter = lib.strings.concatStringsSep " " (builtins.map (s: "~@" + s) [
      "clock"
      "cpu_emulation"
      "debug"
      "module"
      "mount"
      "obsolete"
      "privileged"
      "raw-io"
      "reboot"
      "resources"
      "swap"
    ]);
    UMask = "0027";
    WorkingDirectory = "${config.programs.waybar.package}/bin";
  };
}
