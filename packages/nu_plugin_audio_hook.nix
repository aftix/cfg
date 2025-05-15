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
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_audio_hook";
  version = "0.2.0-unstable-2025-05-05";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "a67c093edcf0e9005f134e2d821a44ff8420f092";
    sha256 = "sha256-1kG3+CCWtQ7M86u/KLHWs3xQu4IurH+VzsJmMbE1GGs=";
  };
  useFetchCargoVendor = true;
  cargoHash = "sha256-Yy63MRHENCfaVGdjm1hInsSwdmkf2pEq2ABFoGeoJUE=";

  nativeBuildInputs = [pkg-config] ++ lib.optionals stdenv.cc.isClang [rustPlatform.bindgenHook];
  buildInputs = [alsa-lib];
  buildFeatures = ["all-decoders"];

  meta = with lib; {
    description = "A nushell plugin to make and play sounds";
    mainProgram = "nu_plugin_audio_hook";
    homepage = "https://github.com/FMotalleb/nu_plugin_audio_hook";
    license = licenses.mit;
    platforms = platforms.linux;
    updateVersion = "branch";
  };
}
