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
  version = "0.108.0-unstable-2025-11-21";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "cba4a591128d1870a6cc2e7cd73afe48faa54e8f";
    sha256 = "sha256-2mbzK30gyorU6nOUY/7cc/ftYtku/CtEpm05JJVL3pI=";
  };
  cargoHash = "sha256-os3j1S61HMRXmTZJPR1HAJgUZ8L9ggIlYckC3qGU754=";

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
