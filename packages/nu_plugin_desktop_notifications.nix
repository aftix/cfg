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
  version = "0.107.0-unstable-2025-09-13";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "aafe8ab71acd93c336c7839a5b0ca00eb4eb70aa";
    sha256 = "sha256-BYaVzIEUA/YQkzxjf/kiCSW69wIaNRx+9MeRCNSvUzE=";
  };
  cargoHash = "sha256-qtQKIlREN7T0gftNXQWg1VDoAHPZyDT6SajWHFVW1A4=";

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
