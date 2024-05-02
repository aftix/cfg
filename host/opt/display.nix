{upkgs, ...}: {
  environment.systemPackages = with upkgs; [
    catppuccin-sddm-corners
    kdePackages.kwin
  ];

  programs.hyprland.enable = true;
  console.useXkbConfig = true;

  services = {
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;

      theme = "catppuccin-sddm-corners";

      autoNumlock = true;
      settings = {
        General = {
          GreeterEnvironment = "QT_WAYLAND_SHELL_INTEGRATION=layer-shell";
        };
        Autologin = {
          Session = "hyprland";
          User = "aftix";
        };
        Wayland = {
          CompositorCommand = "kwin";
        };
        Theme.EnableAvatars = true;
      };
    };

    xserver.xkb = {
      layout = "us";
      variant = "dvorak";
      options = "compose:prsc,caps:escape";
    };
  };

  fonts.packages = with upkgs; [
    inconsolata
    dejavu_fonts
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    dina-font
    proggyfonts
    nerdfonts
    font-awesome
    office-code-pro
    cantarell-fonts
  ];
}
