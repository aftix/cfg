{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_desktop_notifications";
  version = "1.2.4-unstable-2025-02-15";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "f999cc7e2d4444152c130f588c1293f68ecaca2e";
    sha256 = "sha256-jk5bta05+oouDWc/xiB49qeEqu4Al98WWJ8f0kuruYE=";
  };
  useFetchCargoVendor = true;
  cargoHash = "sha256-8jGiW2HgMQ+3XIa2Lso3BGlzWGScdYQT3aemUEJfkv0=";

  meta = with lib; {
    description = "A nushell plugin to send desktop notifications.";
    mainProgram = "nu_plugin_desktop_notifications";
    homepage = "https://github.com/FMotalleb/nu_plugin_desktop_notifications";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
