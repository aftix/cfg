{config, ...}: {
  programs.nh = {
    enable = true;
    inherit (config.my) flake;
    clean = {
      enable = true;
      extraArgs = "--keep-since 7d --keep 10";
    };
  };
}
