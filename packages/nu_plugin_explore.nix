{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_explore";
  version = "18d87a1664d4192797a61647bbac7346508d9723";

  src = fetchFromGitHub {
    owner = "amtoine";
    repo = pname;
    rev = version;
    sha256 = "sha256-9XaKwKi2mxnGEscogKUnW9ByEAqwq/LK4fKrRjB+ozM=";
  };
  useFetchCargoVendor = true;
  cargoHash = "sha256-oxMqJmQMc7Ns/Nt7vjZFx6vs0mmh3hOIv8BtopZ2s6Y=";

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
