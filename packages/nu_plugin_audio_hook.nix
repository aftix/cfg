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
  version = "0.106.1-unstable-2025-08-17";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "578c0140ee229796650a66bb391ef25fe24c2145";
    sha256 = "sha256-2JVMuOwqB7dNbR/ZQtd8SkeTuFChsAy6te/Z2gUlm48=";
  };
  cargoHash = "sha256-bUARtJ6KoWaNid4tHNPI/eVAdqsLXkTXusMoqEyJqXo=";

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
