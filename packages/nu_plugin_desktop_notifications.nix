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
  version = "0.111.0-unstable-2026-04-11";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "f394d1993d0f2bfd6541476b583a8f67dcbb2858";
    sha256 = "sha256-NFIrxgLCbdKSvZuaV6cQYteeUQ0RbcFIPmec49Cp53E=";
  };
  cargoHash = "sha256-A0w5zSTFdOpoYsORbMoM8y8MeBasVy6UJ6TFjlenyqo=";

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
