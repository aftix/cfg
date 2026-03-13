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
  version = "0.111.0-unstable-2026-03-13";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "32cbf806c974e9a3d3e4a042115d6bdc0890b33a";
    sha256 = "sha256-jB8csY918h5OQh4vkOJ+DSkWDieNO5JW4YCkH76DF8g=";
  };
  cargoHash = "sha256-rg9K6v9TDrwQdSWdzLM6F61u0jLbo9Y7SQQ8HJ9iUzw=";

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
