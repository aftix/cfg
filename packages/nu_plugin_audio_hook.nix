# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  alsa-lib,
  nix-update-script,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_audio_hook";
  version = "0.107.0-unstable-2025-09-13";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "7bfce317fd4a5a16b15656177e4c1478a7a70521";
    sha256 = "sha256-iXbK153D2D/WR+0ZnydLBt8TkNQtVJEtAiQ028h5yLU=";
  };
  cargoHash = "sha256-wfcBIJ0WYbFbHPqjwxR0yn0LJusP0g1mJCRLXZIgcFU=";

  nativeBuildInputs = [pkg-config] ++ lib.optionals stdenv.cc.isClang [rustPlatform.bindgenHook];
  buildInputs = [alsa-lib];
  buildFeatures = ["all-decoders"];

  passthru.updateScript = nix-update-script {
    extraArgs = ["--version" "branch"];
  };

  meta = {
    description = "A nushell plugin to make and play sounds";
    mainProgram = "nu_plugin_audio_hook";
    homepage = "https://github.com/FMotalleb/nu_plugin_audio_hook";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
