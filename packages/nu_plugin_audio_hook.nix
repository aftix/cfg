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
  version = "0.106.1-unstable-2025-08-01";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "9d5d45e01ca36ebd79c95017b2676e9b2cf3f359";
    sha256 = "sha256-vuqq4RqynQRGzvM9mjdyfIYq14JljMxzO2ra4VsOWqE=";
  };
  cargoHash = "sha256-aGItITUCroW2qQTfIN45doZ3zSPnQbWcClgfQZ26fpQ=";

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
