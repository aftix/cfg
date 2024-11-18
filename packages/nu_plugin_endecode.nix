{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitea,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_endecode";
  version = "0-unstable-2024-11-16";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "kaathewise";
    repo = "nugins";
    rev = "4d988d5e7772843a3b592a557e71a52d2a956ed0";
    sha256 = "sha256-gxB5OB2hehAX6QCxxLgWmWx0H0AaLGET1/lCRfo5uSo=";
  };
  cargoHash = "sha256-fZVG6JcDbVTaYiS60oLb/QJX6gljrynK6M/zFmci1GE=";

  cargoBuildHook = ''
    export buildAndTestSubdir="./endecode"
  '';
  cargoCheckHook = cargoBuildHook;

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isDarwin [rustPlatform.bindgenHook];
  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk.frameworks.IOKit
    darwin.apple_sdk.frameworks.CoreFoundation
  ];

  meta = with lib; {
    description = "A plugin with various encoding schemes, from Crockford's base-32 to HTML entity escaping.";
    mainProgram = "nu_plugin_endecode";
    homepage = "https://codeberg.org/kaathewise/nugins";
    license = licenses.mpl20;
    platforms = with platforms; all;
  };
}
