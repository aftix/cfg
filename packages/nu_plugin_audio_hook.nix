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
  version = "0.108.0-unstable-2025-10-29";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "26e65ed0690a9ea31091d2492c61ca0c1e26c177";
    sha256 = "sha256-An/E1APLU3wFXuG7g+0P5UxKMrTFVXokJUiPo59wvKA=";
  };
  cargoHash = "sha256-ODFEjDtq3mucQQTEItUE36zGvEtu0L/zEQvAS2X9TC0=";

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
