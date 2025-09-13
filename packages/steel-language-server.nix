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
  nix-update-script,
}:
rustPlatform.buildRustPackage {
  pname = "steel-language-server";
  version = "0-unstable-2025-09-13";

  src = fetchFromGitHub {
    owner = "mattwparas";
    repo = "steel";
    rev = "6e99ccfa40a5a8dbe9b4e1303999494ca0876bcc";
    hash = "sha256-//34ZO2QAz7BgFZQIcGK/j+71dze/R8hQqW4T0a1+B0=";
  };
  cargoHash = "sha256-jitXIzGpLwodYX2faxgdafuLpDGJi+Sr9aFX9QdWHTk=";

  nativeBuildInputs = [makeWrapper openssl pkg-config] ++ lib.optionals stdenv.cc.isClang [rustPlatform.bindgenHook];
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

  passthru.updateScript = nix-update-script {
    extraArgs = ["--version" "branch"];
  };

  meta = {
    description = "An embeddable and extensible scheme dialect built in Rust";
    mainProgram = "steel-language-server";
    homepage = "https://github.com/mattwparas/steel";
    license = lib.licenses.apsl20;
  };
}
