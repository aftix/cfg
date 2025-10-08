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
  version = "0.107.0-unstable-2025-10-07";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "e1c852112525451b31ad508bc1343bd7b3b118df";
    sha256 = "sha256-vzbihEJ2ac9LLQIuLRJ28h3LSPjhRfGnfsE9AMuCguo=";
  };
  cargoHash = "sha256-pe10hkxRilEuEMzFGhTBWPZ4OeYEJFP+3TPNrDaW78o=";

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
