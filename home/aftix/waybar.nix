{
  config,
  upkgs,
  ...
}: {
  home.packages = with upkgs; [waybar];

  programs.waybar.enable = true;

  # Fairly complicated and unchanging, just sync
  xdg.configFile."waybar".source = ./_external.waybar;
}
