{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_compress";
  version = "058e7a263c3f10b749d812d864bf19c7f6199615";

  src = fetchFromGitHub {
    owner = "yybit";
    repo = pname;
    rev = version;
    sha256 = "sha256-S46rXAtXxIURNGvPd9DleNjCj0/NxXHczmCSA04e3xc=";
  };
  cargoHash = "sha256-jJRcsfCy7D+1Nf/QDgN0beMMadzuOTN9wvh25n2kUDA=";
  cargoPatches = [./nu_plugin_compress_add_lockfile.patch];

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
    platforms = with platforms; all;
  };
}
