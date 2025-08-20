# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  stdenv,
  lib,
  callPackage,
  rustPlatform,
  fetchFromGitHub,
  makeWrapper,
  openssl,
  pkg-config,
  steel ? callPackage ./steel.nix {},
}:
rustPlatform.buildRustPackage {
  pname = "steel-language-server";
  version = "0-unstable-2025-08-18";

  src = fetchFromGitHub {
    owner = "mattwparas";
    repo = "steel";
    rev = "af152945614a8778f9af2c4e111dd1ded02316f1";
    hash = "sha256-ErQmpDx1H23O7dU9bphHO16KlfG0cWQAamA7rK0jdGQ=";
  };
  cargoHash = "sha256-tga3KBviXjWbZePpSRueiBb2KnDME87R+BMyVmuSQVg=";

  nativeBuildInputs = [makeWrapper openssl pkg-config] ++ lib.optionals stdenv.hostPlatform.isDarwin [rustPlatform.bindgenHook];
  buildInputs = [steel];

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
    updateVersion = "branch";
  };
}
