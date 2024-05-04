{pkgs, ...}: {
  home.packages = with pkgs; [mpd mpc-cli ncmpcpp];
}
