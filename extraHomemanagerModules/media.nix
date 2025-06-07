# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  config,
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    feh
    ffmpeg_7-full
    imagemagick

    ario
    mpc-cli
  ];

  services = {
    mpd = let
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

    mpd-mpris = {
      enable = true;
      mpd.useLocal = true;
    };
  };

  sops.secrets.mpv = {};

  aftix.shell = {
    aliases = [
      {
        name = "mpvf";
        command = "mpv --fs";
        external = true;
      }
      {
        name = "anipv";
        command = "mpv --slang=en,eng --fs --alang=jpn,jp";
        external = true;
      }
      {
        name = "termpv";
        command = "mpv --vo=kitty --vo-kitty-use-shm=yes";
        external = true;
      }
      {
        name = "ydl";
        command = "yt-dlp -ic -o '%(title)s.%(ext)s' --add-metadata --user-agent 'Mozilla/5.0 (compatible; Googlebot/2.1;+http://www.google.com/bot.html/)' --sponsorblock-remove default";
      }
    ];
  };

  programs = {
    yt-dlp.enable = true;

    mpv = {
      enable = true;
      config = {
        slang = "en";
        vo = "gpu";
        ao = "pipewire";
        video-sync = "display-resample";
        interpolation = true;
        tscale = "oversample";
        hwdec = "best";
        ytdl-format = "bestvideo[height<=1080]+bestaudio/best[height<=1080]/bestvideo+bestaudio/best";
        ytdl-raw-options = "sponsorblock-remove=default";
        save-position-on-quit = true;
        sub-font = lib.mkForce "Noto Serif CJK JP";
        sub-font-size = lib.mkForce 44;
        sub-auto = "fuzzy";
        include = config.sops.secrets.mpv.path;
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

      scripts = with pkgs.mpvScripts; [
        modernx-zydezu
        mpris
        mpv-notify-send
        sponsorblock
        thumbfast
        quality-menu
      ];
    };
  };

  xdg = {
    mimeApps.defaultApplications = pkgs.aftixLib.registerMimes [
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
