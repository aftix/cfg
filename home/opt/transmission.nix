{
  config,
  lib,
  pkgs,
  ...
}: let
  transmission-notify = pkgs.writeShellApplication {
    name = "transmission-notify";
    runtimeInputs = with pkgs; [systemd libnotify gawk transmission_4];
    text = ''
      # shellcheck source=/dev/null
      source <(systemctl --user show-environment | grep -v PATH)
      export DBUS_SESSION_BUS_ADDRESS DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

      PERCENTAGE="$( \
        transmission-remote 127.0.0.1:9091 -t "$TR_TORRENT_ID" -l | \
        awk -v ID="$TR_TORRENT_ID" '$1 == ID {print $2}' 2>&1 \
      )"

      if [ "$PERCENTAGE" != "100%" ]; then
        notify-send --app-name "Transmission" --urgency normal "Torrent Added" "Torrent for \"$TR_TORRENT_NAME\" added to transmission"
      else
        notify-send --app-name "Transmission" --urgency normal "Torrent Completed" "Torrent for \"$TR_TORRENT_NAME\" completed"
      fi
    '';
  };
in {
  home.packages = [pkgs.transmission_4 transmission-notify];

  my.shell.aliases = [
    {
      name = "trem";
      command = "transmission-remote";
      completer = "transmission-remote";
    }
    {
      name = "tract";
      command = "transmission-remote -F '~l:done'";
      completer = {
        name = "tract_complete";
        arguments = "@a";
        body =
          /*
          elvish
          */
          ''
            if (has-key $edit:completion:arg-completer transmission-remote) {
              $edit:completion:arg-completer[transmission-remote] transmission-remote -F '~l:done' $@a
            }
          '';
      };
    }
  ];

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
        "${lib.getExe' pkgs.transmission_4 "transmission-daemon"}" -f --log-error -g "${config.home.homeDirectory}/.config/transmission"'';
      ExecReload = "${lib.getExe' pkgs.coreutils "kill"} -s HUP $MAINPID";
      NoNewPrivileges = true;
      MemoryDenyWriteExecute = true;
      ProtectSystem = true;
      PrivateTmp = true;
    };
    Install.WantedBy = ["default.target"];
  };

  xdg = {
    configFile."transmission/settings.json".text = let
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
        script-torrent-added-filename = lib.getExe transmission-notify;
        script-torrent-done-enabled = true;
        script-torrent-done-filename = lib.getExe transmission-notify;
      };
  };
}
