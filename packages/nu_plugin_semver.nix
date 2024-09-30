{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_semver";
  version = "75f2bfa7b863d1bd89174b28a54a1c8a04eb8e1f";

  src = fetchFromGitHub {
    owner = "abusch";
    repo = pname;
    rev = version;
    sha256 = "sha256-/C9TyLzNuEIrkKUyqjqJQGZDG2iF+BHuIjDzlO9B25A=";
  };
  cargoHash = "sha256-k6pY5rQUmgT+YUUPoIs12ouVi5eOIV19r2/KmpTPxT4=";

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
