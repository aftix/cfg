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
  version = "0-unstable-2025-05-15";

  src = fetchFromGitHub {
    owner = "mattwparas";
    repo = "steel";
    rev = "6e2865c04914748e745ff27c78f245a863fa73df";
    hash = "sha256-oNIdtlzPolQ+UN7Q76jYHp9dwKHfgGulV0oqf4LhRbg=";
  };
  useFetchCargoVendor = true;
  cargoHash = "sha256-fHDdErlNP+y0y27jXQBYP2KLWh2q7jnoYmED9/CwhQ8=";

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
