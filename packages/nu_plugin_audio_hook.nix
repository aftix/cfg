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
  version = "0.110.0-unstable-2026-02-01";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "41456d06a543f7e1e7a15df1d6add2801c083124";
    sha256 = "sha256-lcqPoflxQSsvR6NTK31sbO0kM2t05AwOUHtfYjVnPhs=";
  };
  cargoHash = "sha256-s0AWut6CI5EpaLcmt9wrNY9ziLLNh5nPZlVuz/cuFII=";

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
