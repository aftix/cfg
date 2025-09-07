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
  version = "0.107.0-unstable-2025-09-07";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "96cc85584338220f39299bd637cc33bbfe2f214d";
    sha256 = "sha256-PraOy5uEO7RhFXgLBS2oavxh+hAeZgyGYvl5WRcB2rE=";
  };
  cargoHash = "sha256-4zfic9E/6i6MgkG/LbTF+a4LYF5RmHTzmj4VLBaiF/g=";

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
