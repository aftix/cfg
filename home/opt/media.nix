{
  config,
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
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

  my.shell = {
    aliases = [
      {
        name = "mpvf";
        command = "mpv --fs";
        external = true;
        completer = "mpv";
      }
      {
        name = "anipv";
        command = "mpv --slang=en,eng --fs --alang=jpn,jp";
        external = true;
        completer = "mpv";
      }
      {
        name = "termpv";
        command = "mpv --vo=kitty --vo-kitty-use-shm=yes";
        external = true;
        completer = "mpv";
      }

      {
        name = "ydl";
        command = "yt-dlp -ic -o '%(title)s.%(ext)s' --add-metadata --user-agent 'Mozilla/5.0 (compatible; Googlebot/2.1;+http://www.google.com/bot.html/)'";
        completer = "yt-dlp";
      }
    ];

    elvish.extraFunctions = [
      {
        name = "vdesc";
        arguments = "file";
        body =
          /*
          bash
          */
          ''
            ffprobe -v quiet -print_format json -show_format $file |\
            jq ".format.tags.DESCRIPTION" | sed 's/\\n/\n/g'
          '';
      }
    ];
  };

  programs = {
    yt-dlp.enable = true;

    mpv = {
      enable = true;
      config = {
        slang = "en";
        vo = "dmabuf-wayland";
        ao = "pipewire";
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
        pkgs.mpvScripts.mpris
      ];
    };
  };

  xdg = {
    configFile."ncmpcpp/config".source = (pkgs.formats.keyValue {}).generate "ncmpcpp" {
      ncmpcpp_directory = "${config.home.homeDirectory}/.config/ncmpcpp";
      lyrics_directory = "${config.home.homeDirectory}/.local/share/lyrics";
      mpd_host = "127.0.0.1";
      mpd_port = 6600;
      mpd_music_dir = "${config.home.homeDirectory}/media/music";
    };

    mimeApps.defaultApplications = config.my.lib.registerMimes [
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
