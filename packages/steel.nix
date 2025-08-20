# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  openssl,
  pkg-config,
  makeWrapper,
}:
rustPlatform.buildRustPackage rec {
  pname = "steel";
  version = "0-unstable-2025-08-18";

  src = fetchFromGitHub {
    owner = "mattwparas";
    repo = pname;
    rev = "af152945614a8778f9af2c4e111dd1ded02316f1";
    hash = "sha256-ErQmpDx1H23O7dU9bphHO16KlfG0cWQAamA7rK0jdGQ=";
  };
  cargoHash = "sha256-tga3KBviXjWbZePpSRueiBb2KnDME87R+BMyVmuSQVg=";

  nativeBuildInputs = [makeWrapper openssl pkg-config] ++ lib.optionals stdenv.cc.isClang [rustPlatform.bindgenHook];

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
    updateVersion = "branch";
  };
}
