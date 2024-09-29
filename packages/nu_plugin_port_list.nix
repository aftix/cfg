{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_port_list";
  version = "c7b9284fcab98fe4841f68aaaeb8fd65fd6cb75c";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = version;
    sha256 = "sha256-yIVyMKqP1004ypNf5vtFcsr5jrtYbfprwoVIYiS5F3Q=";
  };
  cargoHash = "sha256-KpPMgsMi/bb4ERpciGo5dKy3kCxKy4QtVtkZgTCsdDY=";

  meta = with lib; {
    description = "A nushell plugin to display all active network connections.";
    mainProgram = "nu_plugin_port_list";
    homepage = "https://github.com/FMotalleb/nu_plugin_port_list/tree/${version}";
    license = licenses.mit;
    platforms = with platforms; all;
  };
}
