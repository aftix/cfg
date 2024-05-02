{upkgs, ...}: {
  environment = {
    systemPackages = with upkgs; [
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
