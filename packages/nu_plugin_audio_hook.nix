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
  version = "0.109.1-unstable-2025-12-05";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "3460019b15d32acd84c2c3efb9a71d6463fb5dfd";
    sha256 = "sha256-fI27N+aj6hxVV46Qxwb80I+wdhuNCsfcGW80lzJEXEU=";
  };
  cargoHash = "sha256-oJWYAcO/6KeG6c8JQPVFWL4DzD61MkfPkqcD5D33D3U=";

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
