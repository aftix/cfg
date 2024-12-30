{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_port_list";
  version = "1.0.0-unstable-2024-12-23";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "db81c56738aecef3414a285bc2cacb1921a7f81d";
    sha256 = "sha256-AdODXvou8QrCUm/J6iatNAp+kIe9uVcCdHOOf1KLog0=";
  };
  cargoHash = "sha256-Buff1aR8qWXnk8B6b/MyikTh0vG2MDH9z6OIDIb9zrw=";

  meta = with lib; {
    description = "A nushell plugin to display all active network connections.";
    mainProgram = "nu_plugin_port_list";
    homepage = "https://github.com/FMotalleb/nu_plugin_port_list";
    license = licenses.mit;
    platforms = with platforms; linux;
  };
}
