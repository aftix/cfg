{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitea,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_endecode";
  version = "738034b769fca04ad6695dd6b0b26d65e2492033";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "kaathewise";
    repo = "nugins";
    rev = version;
    sha256 = "sha256-kMd8hNKRAxlbpVpuZQC2suut3CpIBD9cgN7ABBp9WZw=";
  };
  cargoHash = "sha256-oL1rTkEontUcMeNcr64W0Xvqva+EOWgniJIB8Qlhjmo=";

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
    homepage = "https://codeberg.org/kaathewise/nu-plugin/src/commit/${version}";
    license = licenses.mpl20;
    platforms = with platforms; all;
  };
}
