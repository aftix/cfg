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
  version = "0.109.1-unstable-2025-12-21";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "0b699ecc16052b880ff57ecdc89c9b088ed0563a";
    sha256 = "sha256-h1fG/3j22g9RlLjjsph41jfU9IudIw04eIiSBifpF4E=";
  };
  cargoHash = "sha256-sAE9r5ss1a+CqiqdGM7il0NFK2sMEzk+lsipMwt/JFY=";

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
