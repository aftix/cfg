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
  version = "0.6.0-unstable-2024-12-07";

  src = fetchFromGitHub {
    owner = "mattwparas";
    repo = "steel";
    rev = "81a1950e913e0ae87427a9a9892f6e3722eb5fd7";
    hash = "sha256-RzGJaIE2Rmqut0cQhmE4AbxTGwgmbWfdvymsvuErPUA=";
  };
  cargoHash = "sha256-hF5RVxrDhbbDJQ4l6GaeaebRB6G4zr43/rprA2AKEAw=";

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
