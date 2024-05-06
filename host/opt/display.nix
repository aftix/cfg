{
  pkgs,
  lib,
  hyprPkgs,
  ...
}: let
  inherit (lib) mkDefault;
in {
  environment.systemPackages = with pkgs; [
    catppuccin-sddm-corners
    kdePackages.kwin
  ];

  nix.settings = {
    substituters = ["https://hyprland.cachix.org"];
    trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
  };

  programs.hyprland = {
    enable = mkDefault true;
    package = hyprPkgs.hyprland;
  };

  console.useXkbConfig = true;

  services = {
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;

      theme = mkDefault "catppuccin-sddm-corners";

      autoNumlock = true;
      settings = {
        General = {
          GreeterEnvironment = "QT_WAYLAND_SHELL_INTEGRATION=layer-shell";
        };
        Autologin = {
          Session = mkDefault "hyprland";
          User = mkDefault "aftix";
        };
        Wayland = {
          CompositorCommand = "kwin";
        };
        Theme.EnableAvatars = true;
      };
    };

    xserver.xkb = {
      layout = mkDefault "us";
      variant = mkDefault "dvorak";
      options = mkDefault "compose:prsc,caps:escape";
    };
  };

  fonts.packages = with pkgs; [
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
