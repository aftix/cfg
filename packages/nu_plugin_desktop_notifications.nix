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
  version = "0.109.1-unstable-2025-12-05";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "e26f827c9fdd8c93bc73410a2803234cb9c3a0ad";
    sha256 = "sha256-x5ms9oqY6FBq9j3w4sy94qzDwF4auh1YU2J9AgNZhVY=";
  };
  cargoHash = "sha256-cUJco351fJ4XgINKPxV+4vglWhAtAswS2ysG1XP/fXM=";

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
