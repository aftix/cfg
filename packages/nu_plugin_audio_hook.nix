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
  version = "0.108.0-unstable-2025-11-09";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "a6521185f78692e8ed05f4c2d66e216e1a8e9d6c";
    sha256 = "sha256-ZGRtMQXuiiuQTm9q+q9ThsJ3rouWT4GqrtAaqcoaY64=";
  };
  cargoHash = "sha256-BqybCIdZCTBTP6v/WES7EHeOl8ym1EamRzz+q3UQso4=";

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
