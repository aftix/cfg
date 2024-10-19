{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_desktop_notifications";
  version = "732f56eb74c7c48d2a904df4ab684deb661d3a5d";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = version;
    sha256 = "sha256-Ltjk2FOoRw1GmkWH9Gs6rA/yitq17n06oWiWhnwXAbc=";
  };
  cargoHash = "sha256-9/jlNd6OKJB3XPJVC9p3WtGkhi4+RTwSk0Bu59ZI0hw=";

  meta = with lib; {
    description = "A nushell plugin to send desktop notifications.";
    mainProgram = "nu_plugin_desktop_notifications";
    homepage = "https://github.com/FMotalleb/nu_plugin_desktop_notifications/tree/${version}";
    license = licenses.mit;
    platforms = with platforms; linux;
  };
}
