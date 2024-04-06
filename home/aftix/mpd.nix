{ config, lib, upkgs, ... }:

{
  home.packages = with upkgs; [
    mpd mpc-cli ncmpcpp
  ];

  services.mpd = let dataDir = "${config.home.homeDirectory}/.local/share/mpd"; in {
    enable = true;
    inherit dataDir;
    musicDirectory = "${config.home.homeDirectory}/music";
    playlistDirectory = "${dataDir}/playlists";
    dbFile = "${dataDir}/database";
    extraConfig = lib.concatStrings [
        "log_file \"${config.home.homeDirectory}/.cache/mpd.log\"\n"
        "pid_file \"/run/user/1000/mpd.pid\"\n"
        "state_file \"${config.home.homeDirectory}/.cache/mpd.state\"\n"
        "sticker_file \"${dataDir}/sticker.sql\"\n"

        ''
        input {
          plugin "curl"
        }
        ''

        ''
        audio_output {
          type "pipewire"
          name "Pipewire audio"
        }
        ''
    ];
  };

}

