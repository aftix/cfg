{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_compress";
  version = "3b5361de385752f48d4265c15bff37c2f11bd0d5";

  src = fetchFromGitHub {
    owner = "yybit";
    repo = pname;
    rev = version;
    sha256 = "sha256-J7UpSYGUaD7TFTzmuz3aZ/rX/NWqBMgDinhexARIFFc=";
  };
  useFetchCargoVendor = true;
  cargoHash = "sha256-+3jcFjgbbz35ZjC5/K5gF6FhU/m+Xu0nGPJWq2/l+Qk=";
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
