{upkgs, ...}: {
  home.packages = with upkgs; [waybar];

  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      target = "hyprland-session.target";
    };
  };

  # Fairly complicated and unchanging, just sync
  xdg.configFile."waybar".source = ./_external.waybar;
}
