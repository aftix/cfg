{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  darwin,
  openssl,
  pkg-config,
  makeWrapper,
}:
rustPlatform.buildRustPackage rec {
  pname = "steel";
  version = "0-unstable-2024-12-29";

  src = fetchFromGitHub {
    owner = "mattwparas";
    repo = pname;
    rev = "01d4637fd5efbeb72800ff81eb8d0912166c9b38";
    hash = "sha256-n2OMJnKXbnAKlgKiRdTgKWZvo7pnfAU5K0oqbsPSXyo=";
  };
  useFetchCargoVendor = true;
  cargoHash = "sha256-M/fC8ZViRUjI36xm3ULxD+qPdkfgyMLDXNpOt16iriY=";

  nativeBuildInputs = [makeWrapper openssl pkg-config] ++ lib.optionals stdenv.hostPlatform.isDarwin [rustPlatform.bindgenHook];
  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk.frameworks.IOKit
    darwin.apple_sdk.frameworks.CoreFoundation
    darwin.apple_sdk.frameworks.Security
  ];

  postBuild =
    /*
    bash
    */
    ''
      mkdir -p "$out/share"
      cp -vR "$src/cogs" "$out/share/"
    '';

  doCheck = false;
  postFixup =
    /*
    bash
    */
    ''
      wrapProgram "$out/bin/steel" --set STEEL_HOME "$out/share"
    '';

  meta = with lib; {
    description = "An embeddable and extensible scheme dialect built in Rust";
    mainProgram = "steel";
    homepage = "https://github.com/mattwparas/steel";
    license = licenses.apsl20;
    platforms = platforms.all;
  };
}
