{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_port_list";
  version = "876393a83e7c761f87322701bc4f66c006b794a8";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = version;
    sha256 = "sha256-6EXWh30nPpl4C24fDkYW6JfAIYLOp6rQHZ9gcq1+o20=";
  };
  cargoHash = "sha256-pBP5/yNE7t9NSn2d/T15fJxjGE1VJGwkBQXSw0sQ0uU=";

  meta = with lib; {
    description = "A nushell plugin to display all active network connections.";
    mainProgram = "nu_plugin_port_list";
    homepage = "https://github.com/FMotalleb/nu_plugin_port_list/tree/${version}";
    license = licenses.mit;
    platforms = with platforms; linux;
  };
}
