{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_skim";
  version = "253cc7c7060f9c72cde4175f1c3d575819d40833";

  src = fetchFromGitHub {
    owner = "idanarye";
    repo = pname;
    rev = version;
    sha256 = "sha256-CwBswDVhHqPY4y7fnfL1mpTBMgu6FU8noeVwY+5I/T0=";
  };
  cargoHash = "sha256-cFni5Pp6QFEKQx/1gRsWN5AytdgilZf4PTRVO54M+OE=";

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
