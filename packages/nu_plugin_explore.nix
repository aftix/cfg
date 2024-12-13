{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_explore";
  version = "0.98.0";

  src = fetchFromGitHub {
    owner = "amtoine";
    repo = pname;
    rev = version;
    sha256 = "sha256-EX44IzxEJWK/kzLJ+edUUbGjZMbXJeM+p2/E4kGzrfM=";
  };
  cargoHash = "sha256-VNsHgQIHL8olu4gDsUSYd7lnVZiQDj5AL3rGYDp+qGc=";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isDarwin [rustPlatform.bindgenHook];
  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk.frameworks.IOKit
    darwin.apple_sdk.frameworks.CoreFoundation
  ];

  meta = with lib; {
    description = "A fast structured data explorer for Nushell.";
    mainProgram = "nu_plugin_explore";
    homepage = "https://github.com/amtoine/nu_plugin_explore";
    license = licenses.gpl3Only;
    platforms = with platforms; all;
  };
}
