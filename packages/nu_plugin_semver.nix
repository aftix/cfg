{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_semver";
  version = "0.9.0";

  src = fetchFromGitHub {
    owner = "abusch";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-SXqDsywED76O05pyo5Jw1nxkw6BWiy5NyRMZ8tgHFu0=";
  };
  cargoHash = "sha256-r6lrgKWKY1NBDOFJYoX45rE+9E8Cxr2Di/x/4FFQTMU=";

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
