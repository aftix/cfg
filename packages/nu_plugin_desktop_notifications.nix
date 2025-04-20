{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_desktop_notifications";
  version = "1.2.4-unstable-2025-03-20";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "a016a1cade04228deb4a6dacc902af8932ce9ecb";
    sha256 = "sha256-9I0gNpAZghOhURfO6xVifnd4sijHgPfXZNqeF++4Oyo=";
  };
  useFetchCargoVendor = true;
  cargoHash = "sha256-wFIqy/Tsf1WL+UvoyNjdg2LzX4m4T0n6OkPRkoFxNCY=";

  meta = with lib; {
    description = "A nushell plugin to send desktop notifications.";
    mainProgram = "nu_plugin_desktop_notifications";
    homepage = "https://github.com/FMotalleb/nu_plugin_desktop_notifications";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
