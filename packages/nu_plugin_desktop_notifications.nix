{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_desktop_notifications";
  version = "ae632b5d0ca9799786291adb21cafccb75511d62";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = version;
    sha256 = "sha256-DTo5YH15lKJ6kiNjnNl2Mfby7O+3Bk9VY9fnxDESi00=";
  };
  cargoHash = "sha256-10s1wStXxHRmFGjW/jvEe+M9qIVwkkabk+DrdiRL0CU=";

  meta = with lib; {
    description = "A nushell plugin to send desktop notifications.";
    mainProgram = "nu_plugin_desktop_notifications";
    homepage = "https://github.com/FMotalleb/nu_plugin_desktop_notifications";
    license = licenses.mit;
    platforms = with platforms; linux;
  };
}
