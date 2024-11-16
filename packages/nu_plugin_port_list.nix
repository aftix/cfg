{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_port_list";
  version = "ec644eb07cab21bb62bb09bc7f1353472b1e6cc9";

  src = fetchFromGitHub {
    owner = "aftix";
    repo = pname;
    rev = version;
    sha256 = "sha256-Ihcg7ped7tuIYrg0/zpqp/ruGvkoOY1QUM+P2Pb30GY=";
  };
  cargoHash = "sha256-PXwfztYrDXpcvTBpX9qNff9myVNdxUDIf7WMwuMWj5k=";

  meta = with lib; {
    description = "A nushell plugin to display all active network connections.";
    mainProgram = "nu_plugin_port_list";
    homepage = "https://github.com/FMotalleb/nu_plugin_port_list";
    license = licenses.mit;
    platforms = with platforms; linux;
  };
}
