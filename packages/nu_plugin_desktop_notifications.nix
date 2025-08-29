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
  version = "0.106.1-unstable-2025-08-29";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "b0725dd00d434528825d1966d514c2b4b325afb7";
    sha256 = "sha256-SkwbWzgIcsMCHVkTR5zGsLa5lCCy1VDnvZX3PUq5t20=";
  };
  cargoHash = "sha256-KorNKRngFHWKdhs3r4MDiTotSZZ/3qBnLTpLtdopIZ4=";

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
