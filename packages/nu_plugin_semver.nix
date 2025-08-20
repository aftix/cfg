# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_semver";
  version = "0.11.6";

  src = fetchFromGitHub {
    owner = "abusch";
    repo = pname;
    rev = "refs/tags/v${version}";
    sha256 = "sha256-JF+aY7TW0NGo/E1eFVpBZQoxLxuGja8DSoJy4xgi1Lk=";
  };
  cargoHash = "sha256-609w/7vmKcNv1zSfd+k6TTeU2lQuzHX3W5Y8EqKIiAM=";

  nativeBuildInputs = lib.optionals stdenv.cc.isClang [rustPlatform.bindgenHook];

  meta = {
    description = "This is a plugin for the nu shell to manipulate strings representing versions that conform to the SemVer specification.";
    mainProgram = "nu_plugin_semver";
    homepage = "https://github.com/abusch/nu_plugin_semver";
    license = lib.licenses.mit;
  };
}
