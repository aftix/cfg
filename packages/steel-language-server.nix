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
  version = "0-unstable-2025-09-25";

  src = fetchFromGitHub {
    owner = "mattwparas";
    repo = "steel";
    rev = "27532d855c71a4080f46f69fb9bae0eccfdaea7f";
    hash = "sha256-GxmpBsL/ktR/Sd4q3/5FXQBV0tpdfsnBfbQcUzPIXHw=";
  };
  cargoHash = "sha256-CrmQhOfh7SQ5GvBywmYkfU6wMlgZq2x61+T+mIeQ7z4=";

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
