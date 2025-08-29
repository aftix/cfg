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
  version = "0.106.1-unstable-2025-08-27";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "24bcb023ba9d5ee6ec0194dd55e7dbe385f0f945";
    sha256 = "sha256-1r0RrjZNMh5Or9jNNcKDW85REieSswMLnTR9h/uu0VI=";
  };
  cargoHash = "sha256-hKxnXIITW9cnpgUlz8goMXu47ye37y9flM5bl+iyHdg=";

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
