{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_desktop_notifications";
  version = "503c01c2fec0279306b6cefa68133f8f36f91ced";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = version;
    sha256 = "sha256-UFwuUn3DWKZHMtJTrFt20qa1yszTwAZEbhJ3wTlq54A=";
  };
  cargoHash = "sha256-CQjL1geFU13ezmOO0Z538T0o1aC6QbeKTmhEDxVHIOc=";

  meta = with lib; {
    description = "A nushell plugin to send desktop notifications.";
    mainProgram = "nu_plugin_desktop_notifications";
    homepage = "https://github.com/FMotalleb/nu_plugin_desktop_notifications/tree/${version}";
    license = licenses.mit;
    platforms = with platforms; linux;
  };
}
