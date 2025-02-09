{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_explore";
  version = "023c815e73e193dafe406940912ffb6d0321874d";

  src = fetchFromGitHub {
    owner = "amtoine";
    repo = pname;
    rev = version;
    sha256 = "sha256-Nne0xwUitm883K59ds2OXDWafsrIp2MGXKUbztcf0uM=";
  };
  useFetchCargoVendor = true;
  cargoHash = "sha256-CwPS9NeHfHTkCHlp+6QVjdI6a7DfJr2fjMm9h2fAbIw=";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isDarwin [rustPlatform.bindgenHook];
  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk.frameworks.IOKit
    darwin.apple_sdk.frameworks.CoreFoundation
  ];

  meta = with lib; {
    description = "A fast structured data explorer for Nushell.";
    mainProgram = "nu_plugin_explore";
    homepage = "https://github.com/amtoine/nu_plugin_explore";
    license = licenses.gpl3Only;
    platforms = with platforms; all;
  };
}
