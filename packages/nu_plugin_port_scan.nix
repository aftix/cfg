{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_port_scan";
  version = "0273cd5e5ed677a0b009f5c3f8413b560059e11b";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = version;
    sha256 = "sha256-dLVfaB/zoECUYEWFzgoMhGiz5nSfA5NSH1rYnvP7of8=";
  };
  cargoHash = "sha256-BYhppug4pzJmbu56JjQAXoiYvNdIMH9UoEhE2oom0kI=";

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
