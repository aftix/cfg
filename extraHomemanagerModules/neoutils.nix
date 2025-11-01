# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkDefault mkOverride;
  inherit (lib.lists) optional;
in {
  home = {
    packages = with pkgs;
      [
        ansifilter
        hyperfine
        zenith
        moor
        mprocs
        eza
        dust
        dua
        ast-grep
        ripgrep
        ripgrep-all
        rsync
        fd
        kondo

        pigz
        lzip
        zstd
        pbzip2
      ]
      ++ optional pkgs.stdenv.hostPlatform.isLinux
      trashy;

    sessionVariables = {
      PAGER = mkOverride 900 (lib.getExe pkgs.moor);
      DELTA_PAGER = lib.getExe pkgs.less;
      MANPAGER = mkOverride 900 (lib.getExe pkgs.moor);
      MOOR = mkDefault "-quit-if-one-screen";
    };
  };

  programs.kitty.settings.scrollback_pager = "'${lib.getExe pkgs.moor}' -no-linenumbers";

  aftix.shell = {
    aliases = [
      {
        name = "gzip";
        command = "${lib.getExe' pkgs.pigz "pigz"}";
        docs = false;
      }
      {
        name = "bzip2";
        command = "${lib.getExe' pkgs.pbzip2 "pbzip2"}";
        docs = false;
      }

      {
        name = "eza";
        command = "eza --icons";
        external = true;
        docs = false;
      }
      {
        name = "ezal";
        command = "eza -lhb";
        external = true;
      }
      {
        name = "ezat";
        command = "eza --tree -lhb";
        external = true;
      }

      {
        name = "ka";
        command = "killall";
      }
    ];
  };
}
