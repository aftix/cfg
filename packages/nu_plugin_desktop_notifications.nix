# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  lib,
  rustPlatform,
  fetchFromGitHub,
  lix-update-script,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_desktop_notifications";
  version = "0.111.0-unstable-2026-04-01";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "5510c98fe16d8dc015c08b4110f5b152b3f55f65";
    sha256 = "sha256-gL1Cm8U8oLTzFMmxmTBUFg/OU0p6In/h8DJZXNQ2X34=";
  };
  cargoHash = "sha256-7z2hhasJt19SszpYdAPkQmezI2Jk0Rdpi6dWtkoWIAE=";

  passthru.updateScript = lix-update-script {
    extraArgs = ["--version" "branch"];
  };

  meta = {
    description = "A nushell plugin to send desktop notifications.";
    mainProgram = "nu_plugin_desktop_notifications";
    homepage = "https://github.com/FMotalleb/nu_plugin_desktop_notifications";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
