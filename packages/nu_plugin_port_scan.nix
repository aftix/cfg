{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_port_scan";
  version = "0a1c8e3ddde1b2afa8455b72304758a56bb2997d";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = version;
    sha256 = "sha256-JpMlJKrfn/tW0yZvo7BKdE5ZkPOpKoSffKAVir+m7s0=";
  };
  cargoHash = "sha256-5u9AyDQfMzpgGdpxAK/Jb8VX6FirjYhSeJrawMqVsFw=";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isDarwin [rustPlatform.bindgenHook];
  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk.frameworks.IOKit
    darwin.apple_sdk.frameworks.CoreFoundation
  ];

  meta = with lib; {
    description = "A nushell plugin for scanning ports on a target.";
    mainProgram = "nu_plugin_port_scan";
    homepage = "https://github.com/FMotalleb/nu_plugin_port_scan";
    license = licenses.mit;
    platforms = with platforms; all;
  };
}
