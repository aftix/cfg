{
  upkgs,
  lib,
  ...
}: let
  inherit (lib) mkDefault mkOverride;
in {
  home = {
    packages = with upkgs; [
      hyperfine
      zenith
      moar
      eza
      dust
      ripgrep
      rsync

      pigz
      lzip
      zstd
      pbzip2
    ];

    sessionVariables = {
      PAGER = mkOverride 900 "${upkgs.moar}/bin/moar";
      MANPAGER = mkOverride 900 "${upkgs.moar}/bin/moar";
      MOAR = mkDefault "-quit-if-one-screen";
    };
  };

  my.shell.aliases = [
    {
      name = "gzip";
      command = "${upkgs.pigz}/bin/pigz";
    }
    {
      name = "bzip2";
      command = "${upkgs.pbzip2}/bin/pbzip2";
    }

    {
      name = "eza";
      command = "eza --icons";
      external = true;
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
}
