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
  version = "0-unstable-2025-09-13";

  src = fetchFromGitHub {
    owner = "mattwparas";
    repo = pname;
    rev = "6e99ccfa40a5a8dbe9b4e1303999494ca0876bcc";
    hash = "sha256-//34ZO2QAz7BgFZQIcGK/j+71dze/R8hQqW4T0a1+B0=";
  };
  cargoHash = "sha256-jitXIzGpLwodYX2faxgdafuLpDGJi+Sr9aFX9QdWHTk=";

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
