{pkgs, ...}: {
  environment = {
    systemPackages = with pkgs; [
      libapparmor
      apparmor-pam
      apparmor-utils
      apparmor-bin-utils
      apparmor-kernel-patches
      apparmor-profiles
      apparmor-parser
    ];
  };

  services.dbus.apparmor = "enabled";
  security.apparmor.enable = true;
}
