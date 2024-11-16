{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_dns";
  version = "2577ba77b37500bb69e996a267d10ec169df5c5f";

  src = fetchFromGitHub {
    owner = "dead10ck";
    repo = pname;
    rev = version;
    sha256 = "sha256-raCc9H3g5zrEuvjB15ydqVOJ7TgPfFnRImMjZJ7Q9IE=";
  };
  cargoHash = "sha256-O6THXyWP9jNJs8EGP0J5HstcNx7iSKBEpN4snF6Fdmo=";

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
