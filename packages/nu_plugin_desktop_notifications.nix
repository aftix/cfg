# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_desktop_notifications";
  version = "0.108.0-unstable-2025-11-21";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "85795cf59b4d66f35e2b81b9a8e18e928546aed2";
    sha256 = "sha256-4/HqMY+JvPbhmZwyNjqYgenJ7XWPrjk/Uy+mokPux14=";
  };
  cargoHash = "sha256-YIvcme24xiruEZxHcPpEEPmtkAI7aLzdP8iRW3CV71I=";

  passthru.updateScript = nix-update-script {
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
