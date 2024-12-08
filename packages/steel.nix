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
  version = "0.6.0-unstable-2024-12-07";

  src = fetchFromGitHub {
    owner = "mattwparas";
    repo = pname;
    rev = "81a1950e913e0ae87427a9a9892f6e3722eb5fd7";
    hash = "sha256-RzGJaIE2Rmqut0cQhmE4AbxTGwgmbWfdvymsvuErPUA=";
  };
  cargoHash = "sha256-6q7+ToeJvWpFrgQY5ULS+6ZHMAX0hxAGbiWSmuFm4lY=";

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
