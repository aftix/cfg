{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_port_list";
  version = "1.4.5-unstable-2024-11-16";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "a53277429a39aff7afbbae2562e10ed24d62b132";
    sha256 = "sha256-Ihcg7ped7tuIYrg0/zpqp/ruGvkoOY1QUM+P2Pb30GY=";
  };
  cargoHash = "sha256-cVPJ0pirxYOBHGkXuSZet2Jlhj9AlDx5DO4UPYZgOmc=";

  meta = with lib; {
    description = "A nushell plugin to display all active network connections.";
    mainProgram = "nu_plugin_port_list";
    homepage = "https://github.com/FMotalleb/nu_plugin_port_list";
    license = licenses.mit;
    platforms = with platforms; linux;
  };
}
