{
  stdenv,
  lib,
  callPackage,
  rustPlatform,
  fetchFromGitHub,
  darwin,
  makeWrapper,
  openssl,
  pkg-config,
  steel ? callPackage ./steel.nix {},
}:
rustPlatform.buildRustPackage {
  pname = "steel-language-server";
  version = "0-unstable-2025-04-20";

  src = fetchFromGitHub {
    owner = "mattwparas";
    repo = "steel";
    rev = "fc81e59913977ae23c972216b4d0c2291616bf91";
    hash = "sha256-zbyOAKw/MJr68n628CkD9riiZNRJQ6JuAVXNczqNA+4=";
  };
  useFetchCargoVendor = true;
  cargoHash = "sha256-PWE64CwHCQWvOGeOqdsqX6rAruWlnCwsQpcxS221M3g=";

  nativeBuildInputs = [makeWrapper openssl pkg-config] ++ lib.optionals stdenv.hostPlatform.isDarwin [rustPlatform.bindgenHook];
  buildInputs =
    [steel]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      darwin.apple_sdk.frameworks.IOKit
      darwin.apple_sdk.frameworks.CoreFoundation
      darwin.apple_sdk.frameworks.Security
    ];

  cargoBuildFlags = ["--package" "steel-language-server"];

  doCheck = false;
  postFixup =
    /*
    bash
    */
    ''
      wrapProgram "$out/bin/steel-language-server" \
        --set STEEL_HOME "${steel}/share" \
    '';

  meta = with lib; {
    description = "An embeddable and extensible scheme dialect built in Rust";
    mainProgram = "steel-language-server";
    homepage = "https://github.com/mattwparas/steel";
    license = licenses.apsl20;
    platforms = platforms.all;
  };
}
