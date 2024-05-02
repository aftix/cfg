{upkgs, ...}: {
  home.packages = with upkgs; [
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
}
