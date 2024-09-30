{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_port_scan";
  version = "14ba22305fbbfb5c8160f4a38904bfaa0e0143c0";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = version;
    sha256 = "sha256-2WluXknQQYY2sHW1VwgWJUGL5kRLo1vfVpV7/X3I8RU=";
  };
  cargoHash = "sha256-bW+KtD9S3jncl4djcsAWH0a6ulE9LoCgfH5+WtubAag=";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isDarwin [rustPlatform.bindgenHook];
  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk.frameworks.IOKit
    darwin.apple_sdk.frameworks.CoreFoundation
  ];

  meta = with lib; {
    description = "A nushell plugin for scanning ports on a target.";
    mainProgram = "nu_plugin_port_scan";
    homepage = "https://github.com/FMotalleb/nu_plugin_port_scan/tree/${version}";
    license = licenses.mit;
    platforms = with platforms; all;
  };
}
