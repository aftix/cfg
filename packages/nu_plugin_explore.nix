{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_explore";
  version = "552ccb7c6a3f3780b07cc1d73afec3f99fbd4452";

  src = fetchFromGitHub {
    owner = "amtoine";
    repo = pname;
    rev = version;
    sha256 = "sha256-EX44IzxEJWK/kzLJ+edUUbGjZMbXJeM+p2/E4kGzrfM=";
  };
  cargoHash = "sha256-joVe6+I7Y4L0DLMjDlfZUvxTK3Ow5m/KE/zqJRgiMx0=";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isDarwin [rustPlatform.bindgenHook];
  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk.frameworks.IOKit
    darwin.apple_sdk.frameworks.CoreFoundation
  ];

  meta = with lib; {
    description = "A fast structured data explorer for Nushell.";
    mainProgram = "nu_plugin_explore";
    homepage = "https://github.com/amtoine/nu_plugin_explore/tree/${version}";
    license = licenses.gpl3Only;
    platforms = with platforms; all;
  };
}
