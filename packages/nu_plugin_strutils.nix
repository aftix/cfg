{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_strutils";
  version = "88271e793f1246139cb20a8d92a3d66c4370ad81";

  src = fetchFromGitHub {
    owner = "fdncred";
    repo = pname;
    rev = version;
    sha256 = "sha256-wTOYnnibalPj9SmrwZ8bXcYfk0b8gLGcTF4nWwOEy3c=";
  };
  cargoHash = "sha256-W/QPBDevydB2uOsGI/NVIVwAYeiNAg4PUCtH16r/piI=";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isDarwin [rustPlatform.bindgenHook];
  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk.frameworks.IOKit
    darwin.apple_sdk.frameworks.CoreFoundation
  ];

  meta = with lib; {
    description = "Nushell plugin that implements some string utilities that are not included in nushell.";
    mainProgram = "nu_plugin_strutils";
    homepage = "https://github.com/fdncred/nu_plugin_strutils/tree/${version}";
    license = licenses.mit;
    platforms = with platforms; all;
  };
}
