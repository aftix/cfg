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
  version = "0.103.0-unstable-2025-03-20";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "09a548fca38fd7a8ea3fb90502df3f4d051e60b4";
    sha256 = "sha256-S/+K0oROQJU7ztAG46u3BdDHxFdi//2jX/J3BawU8zo=";
  };
  useFetchCargoVendor = true;
  cargoHash = "sha256-mdQr4Dhp+b7zrjpAlY4t4ToZJRFNAL1FP5T7YEIZ7rk=";

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
