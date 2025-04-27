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
  pname = "nu_plugin_compress";
  version = "0.2.5";

  src = fetchFromGitHub {
    owner = "yybit";
    repo = pname;
    rev = version;
    sha256 = "sha256-sm26bkBgZqPWaCUJxQqKiA8M/eROh6sCnIRrgxbJPTo=";
  };
  useFetchCargoVendor = true;
  cargoHash = "sha256-HAnqF81WIDtrkpxlcXRgrp5qRl1PMj/dYBTjSaVpgkw=";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isDarwin [rustPlatform.bindgenHook];
  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk.frameworks.IOKit
    darwin.apple_sdk.frameworks.CoreFoundation
  ];

  meta = with lib; {
    description = "A nushell plugin for compression and decompression, supporting zstd, gzip, bzip2, and xz.";
    mainProgram = "nu_plugin_compress";
    homepage = "https://github.com/yybit/nu_plugin_compress";
    license = licenses.asl20;
    platforms = platforms.all;
  };
}
