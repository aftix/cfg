{
  config,
  lib,
  upkgs,
  ...
}: {
  home.packages = with upkgs; [mpd mpc-cli ncmpcpp];
}
