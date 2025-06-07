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
  version = "0-unstable-2025-06-06";

  src = fetchFromGitHub {
    owner = "mattwparas";
    repo = pname;
    rev = "110b1f6c9221da0567ee7e8f9c811142b266203f";
    hash = "sha256-D8BFhGiROU85oDiJrX0iUzQX79moZalYM1OSgHdWrWs=";
  };
  cargoHash = "sha256-yLTVPCw50WSPSvNwKTt18DAp1cG18knQU7M3BlMmYGI=";

  nativeBuildInputs = [makeWrapper openssl pkg-config] ++ lib.optionals stdenv.hostPlatform.isDarwin [rustPlatform.bindgenHook];

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
