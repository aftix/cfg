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
  version = "0.110.0-unstable-2026-03-03";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "f323497a442d709a93849ac6392976c8fd754182";
    sha256 = "sha256-4SjwNRH611x2rSLxatBdUVdn/jpBDOSzORqjYssemc4=";
  };
  cargoHash = "sha256-sG/ga+rXm5OZmdNMN0w+1z+OfZWKGNxi/sMsqEvaBs0=";

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
