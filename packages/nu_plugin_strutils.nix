# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_strutils";
  version = "0.10.0";

  src = fetchFromGitHub {
    owner = "fdncred";
    repo = pname;
    rev = "d2e29919841d3a796e51d6724b70213277754948";
    sha256 = "sha256-xictRAkMnVEbNjEVO4w9XN0auHX5mcmnyFdlaFoVunA=";
  };
  useFetchCargoVendor = true;
  cargoHash = "sha256-4r5TH3t61TjWMoKuzStuUQM779IpD1t4K98OuOQ2L8M=";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isDarwin [rustPlatform.bindgenHook];
  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk.frameworks.IOKit
    darwin.apple_sdk.frameworks.CoreFoundation
  ];

  meta = with lib; {
    description = "Nushell plugin that implements some string utilities that are not included in nushell.";
    mainProgram = "nu_plugin_strutils";
    homepage = "https://github.com/fdncred/nu_plugin_strutils";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
