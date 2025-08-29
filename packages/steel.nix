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
  nix-update-script,
}:
rustPlatform.buildRustPackage rec {
  pname = "steel";
  version = "0-unstable-2025-08-29";

  src = fetchFromGitHub {
    owner = "mattwparas";
    repo = pname;
    rev = "9668db4eb00b25b6f5cfddc27a4d1aed63ecce75";
    hash = "sha256-Tpzsna8jZbsmNeFK/VoqTQTti82bXF6ugqHnd4bGZm0=";
  };
  cargoHash = "sha256-a7wene1oI2lhMUo8iguosXyk1G12bhrEdK7IJ/WgRq4=";

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

  passthru.updateScript = nix-update-script {
    extraArgs = ["--version" "branch"];
  };

  meta = {
    description = "An embeddable and extensible scheme dialect built in Rust";
    mainProgram = "steel";
    homepage = "https://github.com/mattwparas/steel";
    license = lib.licenses.apsl20;
  };
}
