{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_semver";
  version = "0.11.2";

  src = fetchFromGitHub {
    owner = "abusch";
    repo = pname;
    rev = "refs/tags/v${version}";
    sha256 = "sha256-k9LHrFAb4yyJShFFwvSP8M2S+/JH92r3fCUn1NL4Nog=";
  };
  useFetchCargoVendor = true;
  cargoHash = "sha256-3u6MMmNBEUarpp6NXzLtuG3dqb6MX3tQ3zISGyiG2aI=";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isDarwin [rustPlatform.bindgenHook];
  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk.frameworks.IOKit
    darwin.apple_sdk.frameworks.CoreFoundation
  ];

  meta = with lib; {
    description = "This is a plugin for the nu shell to manipulate strings representing versions that conform to the SemVer specification.";
    mainProgram = "nu_plugin_semver";
    homepage = "https://github.com/abusch/nu_plugin_semver";
    license = licenses.mit;
    platforms = with platforms; all;
  };
}
