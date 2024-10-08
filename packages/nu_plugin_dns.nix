{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_dns";
  version = "629fee177147909309292df8c50bc8aa72aabcd3";

  src = fetchFromGitHub {
    owner = "dead10ck";
    repo = pname;
    rev = version;
    sha256 = "sha256-d981E4NTVeQcCdGtStWZLwYNFpU/PeAvQ4mxzMmY054=";
  };
  cargoHash = "sha256-7Z9tOtsPwTG9l7wVTlMjQBr3Zk7djpBA2qhbFtxr92U=";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isDarwin [rustPlatform.bindgenHook];
  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk.frameworks.IOKit
    darwin.apple_sdk.frameworks.CoreFoundation
    darwin.apple_sdk.frameworks.Security
  ];

  meta = with lib; {
    description = "A DNS utility for nushell.";
    mainProgram = "nu_plugin_dns";
    homepage = "https://github.com/dead10ck/nu_plugin_dns/tree/${version}";
    license = licenses.mpl20;
    platforms = with platforms; all;
  };
}
