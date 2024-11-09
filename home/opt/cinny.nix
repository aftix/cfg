{pkgs, ...}: {
  home.packages = [pkgs.cinny-desktop];
  my.cinny = true;
}
