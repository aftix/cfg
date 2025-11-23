{
  config,
  lib,
  ...
}: {
  programs.hyprland.enable = true;

  # Autologin as aftix user
  services.greetd.settings.initial_session = {
    command = lib.getExe config.programs.hyprland.package;
    user = lib.mkOverride 990 "aftix";
  };
}
