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
  version = "0.111.0-unstable-2026-04-09";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "86dfa55764c6c77aeac333af85ba29485b40bdd3";
    sha256 = "sha256-VR1TGPbSs1enZ/C/2dA1IME1SV0KQYakIw8J7alNe68=";
  };
  cargoHash = "sha256-a3t+cilpb904gSKqWmKKMF9wX6QdRrJWy0rR/0LF1Ms=";

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
