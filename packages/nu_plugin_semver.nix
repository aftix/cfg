{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_semver";
  version = "2bc0b459f9062cde9c7a7f516b8057ea9eece670";

  src = fetchFromGitHub {
    owner = "abusch";
    repo = pname;
    rev = version;
    sha256 = "sha256-SXqDsywED76O05pyo5Jw1nxkw6BWiy5NyRMZ8tgHFu0=";
  };
  cargoHash = "sha256-d6IG+7FUg10zY6GiUR/RKeWNFLCX6Xp44j55quWwzo4=";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isDarwin [rustPlatform.bindgenHook];
  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk.frameworks.IOKit
    darwin.apple_sdk.frameworks.CoreFoundation
  ];

  meta = with lib; {
    description = "This is a plugin for the nu shell to manipulate strings representing versions that conform to the SemVer specification.";
    mainProgram = "nu_plugin_semver";
    homepage = "https://github.com/abusch/nu_plugin_semver/tree/${version}";
    license = licenses.mit;
    platforms = with platforms; all;
  };
}
