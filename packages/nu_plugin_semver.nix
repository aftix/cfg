# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_semver";
  version = "0.11.4";

  src = fetchFromGitHub {
    owner = "abusch";
    repo = pname;
    rev = "refs/tags/v${version}";
    sha256 = "sha256-VTMaZUYgb7wZqiZmd5IVxQsjbHx3QC75VQQdJqaCvfY=";
  };
  useFetchCargoVendor = true;
  cargoHash = "sha256-oPP4lwXe4jJLfTjUWfaHxQX6CfHbXO5DajyK4r/l6bo=";

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
    platforms = platforms.all;
  };
}
