{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_desktop_notifications";
  version = "cfeeac31e29ef66b6b53cfa1bb5972f5d3da388c";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = version;
    sha256 = "sha256-X2Sp+D4PB4U4o+zwYlewPudWsoC+gE1O4fr2vYqsWkM=";
  };
  cargoHash = "sha256-nnUI/bQNQkdk6QuAGYi6VLFbmdrZqN6ekYEuFZvDfJU=";

  meta = with lib; {
    description = "A nushell plugin to send desktop notifications.";
    mainProgram = "nu_plugin_desktop_notifications";
    homepage = "https://github.com/FMotalleb/nu_plugin_desktop_notifications";
    license = licenses.mit;
    platforms = with platforms; linux;
  };
}
