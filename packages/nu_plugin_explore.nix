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
  pname = "nu_plugin_explore";
  version = "0.101.0";

  src = fetchFromGitHub {
    owner = "amtoine";
    repo = pname;
    rev = "fa5ab698463489bfc782077915f636661712a217";
    sha256 = "sha256-ziHjjNdLDgyrXOgFcQC34zjKX4dT7SvfS5xOrr+VeMc=";
  };
  useFetchCargoVendor = true;
  cargoHash = "sha256-YqmU+j1dcw9YN0p3h+s4hJpt1O6z6EYrSj8lApQX93o=";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isDarwin [rustPlatform.bindgenHook];
  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk.frameworks.IOKit
    darwin.apple_sdk.frameworks.CoreFoundation
  ];

  meta = with lib; {
    description = "A fast structured data explorer for Nushell.";
    mainProgram = "nu_plugin_explore";
    homepage = "https://github.com/amtoine/nu_plugin_explore";
    license = licenses.gpl3Only;
    platforms = platforms.all;
  };
}
