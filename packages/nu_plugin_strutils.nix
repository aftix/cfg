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
  pname = "nu_plugin_strutils";
  version = "0.15.0";

  src = fetchFromGitHub {
    owner = "fdncred";
    repo = pname;
    rev = "d2e29919841d3a796e51d6724b70213277754948";
    sha256 = "sha256-xictRAkMnVEbNjEVO4w9XN0auHX5mcmnyFdlaFoVunA=";
  };
  cargoHash = "sha256-4r5TH3t61TjWMoKuzStuUQM779IpD1t4K98OuOQ2L8M=";

  nativeBuildInputs = lib.optionals stdenv.cc.isClang [rustPlatform.bindgenHook];

  passthru.updateScript = nix-update-script {};

  meta = {
    description = "Nushell plugin that implements some string utilities that are not included in nushell.";
    mainProgram = "nu_plugin_strutils";
    homepage = "https://github.com/fdncred/nu_plugin_strutils";
    license = lib.licenses.mit;
  };
}
