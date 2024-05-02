{
  config,
  upkgs,
  mylib,
  lib,
  ...
}: {
  home.packages = with upkgs; [
    feh
    ffmpeg_5
    imagemagick

    mpc-cli
    ncmpcpp
  ];

  services.mpd = let
    dataDir = "${config.home.homeDirectory}/.local/share/mpd";
  in {
    enable = true;
    inherit dataDir;
    musicDirectory = "${config.home.homeDirectory}/media/music";
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

  programs = {
    yt-dlp.enable = true;

    mpv = {
      enable = true;
      config = {
        slang = "en";
        vo = "gpu";
        video-sync = "display-resample";
        interpolation = true;
        tscale = "oversample";
        hwdec = "best";
        ytdl-format = "bestvideo[height<=1080]+bestaudio/best[height<=1080]/bestvideo+bestaudio/best";
        save-position-on-quit = true;
        sub-font = "Source Han Serif JP";
        sub-auto = "fuzzy";
      };

      profiles = {
        "extension.gif".loop-file = "inf";

        "extension.jpg" = {
          pause = true;
          border = false;
          osc = false;
        };

        "extension.png" = {
          pause = true;
          border = false;
          osc = false;
        };
      };

      scripts = [
        upkgs.mpvScripts.mpris
      ];
    };
  };

  xdg = {
    configFile."ncmpcpp/config".source = (upkgs.formats.keyValue {}).generate "ncmpcpp" {
      ncmpcpp_directory = "${config.home.homeDirectory}/.config/ncmpcpp";
      lyrics_directory = "${config.home.homeDirectory}/.local/share/lyrics";
      mpd_host = "127.0.0.1";
      mpd_port = 6600;
      mpd_music_dir = "${config.home.homeDirectory}/media/music";
    };

    mimeApps.defaultApplications = mylib.registerMimes [
      {
        application = "feh";
        mimetypes = [
          "image/bmp"
          "image/apng"
          "image/png"
          "image/tiff"
          "image/jpeg"
          "image/gif"
          "image/vnd.microsoft.icon"
          "image/tiff"
        ];
      }
      {
        application = "mpv";
        mimetypes = [
          "image/avif"
          "video/mp4"
          "video/avi"
          "application/x-msvideo"
          "video/mkv"
          "video/mpeg"
          "video/webm"
          "audio/aac"
          "audio/flac"
          "audio/ogg"
          "audio/mp3"
        ];
      }
    ];
  };
}
