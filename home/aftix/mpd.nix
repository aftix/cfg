{
  config,
  lib,
  upkgs,
  ...
}: {
  home.packages = with upkgs; [mpd mpc-cli ncmpcpp];

  services.mpd = let
    dataDir = "${config.home.homeDirectory}/.local/share/mpd";
  in {
    enable = true;
    inherit dataDir;
    musicDirectory = "${config.home.homeDirectory}/music";
    playlistDirectory = "${dataDir}/playlists";
    dbFile = "${dataDir}/database";
    extraConfig = lib.concatStrings [
      ''
        log_file "${config.home.homeDirectory}/.cache/mpd.log"
      ''
      ''
        pid_file "/run/user/1000/mpd.pid"
      ''
      ''
        state_file "${config.home.homeDirectory}/.cache/mpd.state"
      ''
      ''
        sticker_file "${dataDir}/sticker.sql"
      ''

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

  xdg.configFile."ncmpcpp/config".text = ''
    ncmpcpp_directory = ${config.home.homeDirectory}/.config/ncmpcpp
    lyrics_directory = ${config.home.homeDirectory}/.local/share/lyrics
    mpd_host = 127.0.0.1
    mpd_port = 6600
    mpd_music_dir = ${config.home.homeDirectory}/music
  '';
}
