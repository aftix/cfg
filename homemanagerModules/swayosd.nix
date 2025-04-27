{
  osConfig,
  lib,
  ...
}: let
  cfg = osConfig.my.swayosd;
in {
  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package];

    systemd.user.services.swayosd = {
      Install.WantedBy = ["graphical-session.target"];
      Service = {
        ExecStart = lib.getExe' cfg.package "swayosd-server";
        Restart = "on-failure";
        Type = "simple";
      };
      Unit = {
        After = ["graphical-session-pre.target"];
        ConditionEnvironment = ["WAYLAND_DISPLAY"];
        Description = "A OSD window for common actions like volume and capslock";
      };
    };
  };
}
