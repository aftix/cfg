{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.my.swayosd;
in {
  options.my.swayosd = {
    enable = lib.mkEnableOption "swayosd";
    package = lib.mkPackageOption pkgs "swayosd" {
      default = ["swayosd"];
    };
  };

  config = lib.mkIf cfg.enable {
    services.dbus.packages = [cfg.package];
    systemd.services.swayosd = {
      after = ["graphical.target"];
      description = "SwayOSD LibInput backend for listening to certain keys like CapsLock, ScrollLock, VolumeUp, etc...";
      documentation = ["https://github.com/ErikReider/SwayOSD"];
      partOf = ["graphical.target"];
      script = lib.getExe' cfg.package "swayosd-libinput-backend";
      serviceConfig =
        config.my.systemdHardening
        // {
          BusName = "org.erikreider.swayosd";
          Restart = "on-failure";
        };
      wantedBy = ["graphical.target"];
    };
  };
}
