{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_port_scan";
  version = "c3307b4bc135621a14a140ed2a8c2b51fd7c070c";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = version;
    sha256 = "sha256-S0tM3KlC2S1VLZt9lyVif/aGDLMo8U0svS8KmtGUKxE=";
  };
  cargoHash = "sha256-fWidskbzyiJUgkyGfQnK5CKi7IbmSaA9p6mDShCEqEc=";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isDarwin [rustPlatform.bindgenHook];
  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk.frameworks.IOKit
    darwin.apple_sdk.frameworks.CoreFoundation
  ];

  meta = with lib; {
    description = "A nushell plugin for scanning ports on a target.";
    mainProgram = "nu_plugin_port_scan";
    homepage = "https://github.com/FMotalleb/nu_plugin_port_scan";
    license = licenses.mit;
    platforms = with platforms; all;
  };
}
