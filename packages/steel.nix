# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
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
  version = "0-unstable-2025-04-20";

  src = fetchFromGitHub {
    owner = "mattwparas";
    repo = pname;
    rev = "fc81e59913977ae23c972216b4d0c2291616bf91";
    hash = "sha256-zbyOAKw/MJr68n628CkD9riiZNRJQ6JuAVXNczqNA+4=";
  };
  useFetchCargoVendor = true;
  cargoHash = "sha256-PWE64CwHCQWvOGeOqdsqX6rAruWlnCwsQpcxS221M3g=";

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
