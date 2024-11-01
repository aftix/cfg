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
        hyperfine
        zenith
        moar
        eza
        dust
        ripgrep
        rsync
        fd

        pigz
        lzip
        zstd
        pbzip2
      ]
      ++ optional (lib.strings.hasSuffix "-linux" pkgs.system)
      trashy;

    sessionVariables = {
      PAGER = mkOverride 900 "${lib.getExe pkgs.moar}";
      MANPAGER = mkOverride 900 "${lib.getExe pkgs.moar}";
      MOAR = mkDefault "-quit-if-one-screen";
    };
  };

  programs.kitty.settings.scrollback_pager = "'${lib.getExe pkgs.moar}' -no-linenumbers";

  my.shell = {
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
        completer = "eza";
      }
      {
        name = "ezat";
        command = "eza --tree -lhb";
        external = true;
        completer = "eza";
      }

      {
        name = "ka";
        command = "killall";
        completer = "killall";
      }
    ];

    elvish = {
      extraFunctions = [
        {
          name = "restore";
          body =
            /*
            bash
            */
            ''
              trash list | fzf --multi | awk '{$1=$1;print}' | rev | cut -d ' ' -f1 | rev | xargs trashy restore --match=exact --force
            '';
        }
        {
          name = "empty";
          body =
            /*
            bash
            */
            ''
              trash list | fzf --multi | awk '{$1=$1;print}' | rev | cut -d ' ' -f1 | rev | xargs trashy empty --match=exact --force
            '';
        }
      ];
    };
  };
}
