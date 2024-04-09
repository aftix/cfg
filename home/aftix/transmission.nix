{
  config,
  upkgs,
  spkgs,
  ...
}: {
  home.packages = with upkgs; [transmission_4];

  # The nix options for transmission do not work for home manager
  # So I'm defining my own systemd service
  systemd.user.services.transmission = {
    Unit = {
      Description = "Transmission BitTorrent Daemon";
      Wants = ["network-online.target"];
      After = ["network-online.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = ''
        "${upkgs.transmission}/bin/transmission-daemon" -f --log-error -g "${config.home.homeDirectory}/.config/transmission"'';
      ExecReload = "/run/current-system/sw/bin/kill -s HUP $MAINPID";
      NoNewPrivileges = true;
      MemoryDenyWriteExecute = true;
      ProtectSystem = true;
      PrivateTmp = true;
    };
    Install.WantedBy = ["default.target"];
  };

  xdg.configFile."transmission/settings.json".text = let
    torrentDir = "${config.home.homeDirectory}/.transmission";
  in
    builtins.toJSON {
      home = "${config.home.homeDirectory}";
      watch-dir-enabled = true;
      watch-dir = "${torrentDir}/watch";
      incomplete-dir-enabled = true;
      incomplete-dir = "${torrentDir}/incomplete";
      download-dir = "${config.home.homeDirectory}/media/torrent";

      trash-original-torrent-files = true;
      script-torrent-added-enabled = true;
      script-torrent-added-filename = "${config.home.homeDirectory}/.config/transmission/event.sh";
      script-torrent-done-enabled = true;
      script-torrent-done-filename = "${config.home.homeDirectory}/.config/transmission/event.sh";
    };

  xdg.configFile."transmission/event.sh" = {
    executable = true;
    text = ''
      #!${upkgs.bash}/bin/bash

      source <("${spkgs.systemd}/bin/systemctl" --user show-environment)
      export DBUS_SESSION_BUS_ADDRESS DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

      TREM="${upkgs.transmission}/bin/transmission-remote"
      NOTIFY="${upkgs.libnotify}/bin/notify-send"

      PERCENTAGE="$( \
        "$TREM" 127.0.0.1:9091 -t "$TR_TORRENT_ID" -l | \
        /run/current-system/sw/bin/awk -v ID="$TR_TORRENT_ID" '$1 == ID {print $2}' 2>&1 \
      )"

      if [ "$PERCENTAGE" != "100%" ]; then
        "$NOTIFY" --app-name "Transmission" --urgency normal "Torrent Added" "Torrent for \"$TR_TORRENT_NAME\" added to transmission"
      else
        "$NOTIFY" --app-name "Transmission" --urgency normal "Torrent Completed" "Torrent for \"$TR_TORRENT_NAME\" completed"
      fi
    '';
  };
}
