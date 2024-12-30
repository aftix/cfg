{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_compress";
  version = "faca57a8cdfb888e1c245860c48ce709a6750a28";

  src = fetchFromGitHub {
    owner = "yybit";
    repo = pname;
    rev = version;
    sha256 = "sha256-CbvgEJ6nGbqEhLYlFCCYyERS0im7ehvtT8Zpf7PnZFA=";
  };
  cargoHash = "sha256-9pwePrXgDY3z5TjkMv7zxGUSoRNbYDqx0QLuZIlFwIY=";
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
