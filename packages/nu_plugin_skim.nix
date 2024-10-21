{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_skim";
  version = "0.8.0";

  src = fetchFromGitHub {
    owner = "idanarye";
    repo = pname;
    rev = version;
    sha256 = "sha256-3q2qt35lZ07N8E3p4/BoYX1H4B8qcKXJWnZhdJhgpJE=";
  };
  cargoHash = "sha256-+RYrQsB8LVjxZsQ7dVDK6GT6nXSM4b+qpILOe0Q2SjA=";

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
