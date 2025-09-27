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
  version = "0.107.0-unstable-2025-09-27";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "fd6e21b3029ce53d7ba7b2c5e359674931e1dd81";
    sha256 = "sha256-OPQItp0UBcSfz5qocAQ8tv7Zn46N0XRZeu/mBkh2DFM=";
  };
  cargoHash = "sha256-+NONlnWnD/mvF41ePXYbtOGuvZMrrGwfYfQuauu5viA=";

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
