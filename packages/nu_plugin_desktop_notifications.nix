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
  version = "0.112.2-unstable-2026-04-23";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "887a0fa8c6e93d85523fdbbd26f7d9155a3164cc";
    sha256 = "sha256-ezcuELViyRcz/0m5lM2x8aL+lqOWUw5967kdNaREpQI=";
  };
  cargoHash = "sha256-Gwd3wvZZ0139JAAyayiNvqAv6HFSYops8GnsJVCY4Uw=";

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
