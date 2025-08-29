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
  pname = "nu_plugin_dns";
  version = "3.0.6-unstable-2024-12-09";

  src = fetchFromGitHub {
    owner = "dead10ck";
    repo = pname;
    rev = "0453d9adbbadc00e4ff22261cf464d10ea4a4ccc";
    sha256 = "sha256-a1EQV/UX4+gB14jHMReLFbOmabZ5r40FgaHO+60IPME=";
  };
  cargoHash = "sha256-5DBMej3NWYRTkoDs1a5qoydnhDW0TKBYanuMXeMSs5o=";

  nativeBuildInputs = lib.optionals stdenv.cc.isClang [rustPlatform.bindgenHook];

  passthru.updateScript = nix-update-script {
    extraArgs = ["--version" "branch"];
  };

  meta = {
    description = "A DNS utility for nushell.";
    mainProgram = "nu_plugin_dns";
    homepage = "https://github.com/dead10ck/nu_plugin_dns";
    license = lib.licenses.mpl20;
  };
}
