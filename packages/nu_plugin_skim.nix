{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_skim";
  version = "6de10d1995f243b8ae7331103a71ea895578e843";

  src = fetchFromGitHub {
    owner = "idanarye";
    repo = pname;
    rev = version;
    sha256 = "sha256-sD+oStE+w39/psFErdcrItciSNyXRtHDnKz3gT9mrX4=";
  };
  cargoHash = "sha256-HEhG6KRnirZCjryKuQexfF7Kg2KFEPMN6TCen+D8/zw=";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isDarwin [rustPlatform.bindgenHook];
  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk.frameworks.IOKit
    darwin.apple_sdk.frameworks.CoreFoundation
  ];

  meta = with lib; {
    description = "A nushell plugin that adds integrates the skim fuzzy finder.";
    mainProgram = "nu_plugin_skim";
    homepage = "https://github.com/idanarye/nu_plugin_skim/tree/${version}";
    license = licenses.mit;
    platforms = with platforms; all;
  };
}
