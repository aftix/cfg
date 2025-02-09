{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_dns";
  version = "0453d9adbbadc00e4ff22261cf464d10ea4a4ccc";

  src = fetchFromGitHub {
    owner = "dead10ck";
    repo = pname;
    rev = version;
    sha256 = "sha256-a1EQV/UX4+gB14jHMReLFbOmabZ5r40FgaHO+60IPME=";
  };
  useFetchCargoVendor = true;
  cargoHash = "sha256-5DBMej3NWYRTkoDs1a5qoydnhDW0TKBYanuMXeMSs5o=";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isDarwin [rustPlatform.bindgenHook];
  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk.frameworks.IOKit
    darwin.apple_sdk.frameworks.CoreFoundation
    darwin.apple_sdk.frameworks.Security
  ];

  meta = with lib; {
    description = "A DNS utility for nushell.";
    mainProgram = "nu_plugin_dns";
    homepage = "https://github.com/dead10ck/nu_plugin_dns";
    license = licenses.mpl20;
    platforms = with platforms; all;
  };
}
