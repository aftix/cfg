{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_strutils";
  version = "0.8.0-unstable-2024-12-25";

  src = fetchFromGitHub {
    owner = "fdncred";
    repo = pname;
    rev = "e08358d612147b1a7f0b04eef66e4c05b96b21eb";
    sha256 = "sha256-38j2SB9ynahlDOHHKB8Iqn07O5dMLcVGBywzUbVKbww=";
  };
  useFetchCargoVendor = true;
  cargoHash = "sha256-W6vZ2WHRSVinJmpBf8jnVl5E19WIhDjDA9OTipemUyk=";

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
    platforms = with platforms; all;
  };
}
