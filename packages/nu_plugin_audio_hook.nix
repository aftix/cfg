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
  version = "0.108.0-unstable-2025-10-17";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "db29987f07d6916b7588f31236197f8602304371";
    sha256 = "sha256-yUpaqROBYeR7YGWu1pBKVg8rd+zhcX/+TRQNERh3hJw=";
  };
  cargoHash = "sha256-hYN26yPnhhqPIvuCLx6Ksvt/yggHqE78JHyESgWm9zk=";

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
