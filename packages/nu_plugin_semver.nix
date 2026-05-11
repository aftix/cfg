# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  lix-update-script,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_semver";
  version = "0.11.16";

  src = fetchFromGitHub {
    owner = "abusch";
    repo = pname;
    tag = "v${version}";
    sha256 = "sha256-LgB2a14ZIQvNpvYU4nu3AEcwjjWIpJlMS4OGB+dHj2E=";
  };
  cargoHash = "sha256-PunvfZbghJzcpAMLDIozec2GAklWTosPUWlBJ76lPV8=";

  nativeBuildInputs = lib.optionals stdenv.cc.isClang [rustPlatform.bindgenHook];

  passthru.updateScript = lix-update-script {};

  meta = {
    description = "This is a plugin for the nu shell to manipulate strings representing versions that conform to the SemVer specification.";
    mainProgram = "nu_plugin_semver";
    homepage = "https://github.com/abusch/nu_plugin_semver";
    license = lib.licenses.mit;
  };
}
