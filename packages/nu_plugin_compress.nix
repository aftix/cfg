# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
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
  cargoHash = "sha256-HAnqF81WIDtrkpxlcXRgrp5qRl1PMj/dYBTjSaVpgkw=";

  nativeBuildInputs = lib.optionals stdenv.cc.isClang [rustPlatform.bindgenHook];

  meta = with lib; {
    description = "A nushell plugin for compression and decompression, supporting zstd, gzip, bzip2, and xz.";
    mainProgram = "nu_plugin_compress";
    homepage = "https://github.com/yybit/nu_plugin_compress";
    license = licenses.asl20;
    platforms = platforms.all;
  };
}
