{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_strutils";
  version = "0.7.0-unstable-2024-11-15";

  src = fetchFromGitHub {
    owner = "fdncred";
    repo = pname;
    rev = version;
    sha256 = "sha256-vWg/l8Y1zC8i7A/VBF+lBrgB/NyotZiQcLyb68vbP08=";
  };
  cargoHash = "sha256-A6TfIh2mIHHUwY55VQKbb0ZrHGwOqi1JawpwJLkXjc0=";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isDarwin [rustPlatform.bindgenHook];
  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk.frameworks.IOKit
    darwin.apple_sdk.frameworks.CoreFoundation
  ];

  meta = with lib; {
    description = "Nushell plugin that implements some string utilities that are not included in nushell.";
    mainProgram = "nu_plugin_strutils";
    homepage = "https://github.com/fdncred/nu_plugin_strutils";
    license = licenses.mit;
    platforms = with platforms; all;
  };
}
