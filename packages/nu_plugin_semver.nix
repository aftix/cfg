# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_semver";
  version = "0.11.9";

  src = fetchFromGitHub {
    owner = "abusch";
    repo = pname;
    tag = "v${version}";
    sha256 = "sha256-RdVN2KqEf/5Ir8n6+CUXYZMBb2GFenYNKcudq9Abg9g=";
  };
  cargoHash = "sha256-/SB1jCZFM56v0bnxwOqds6N3jGuIpM7RtZaqiSk1xdE=";

  nativeBuildInputs = lib.optionals stdenv.cc.isClang [rustPlatform.bindgenHook];

  passthru.updateScript = nix-update-script {};

  meta = {
    description = "This is a plugin for the nu shell to manipulate strings representing versions that conform to the SemVer specification.";
    mainProgram = "nu_plugin_semver";
    homepage = "https://github.com/abusch/nu_plugin_semver";
    license = lib.licenses.mit;
  };
}
