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
  version = "0.108.0-unstable-2025-10-29";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "af66271e906aa1da3d45244e19a61effa75b1ea4";
    sha256 = "sha256-ehDpEHRVHm77uAT87sQVuBzX/iLF7mK1846o7aLx+Z8=";
  };
  cargoHash = "sha256-xxhE44MbgzcYD9NDH/isI3e+3IXzPUu7AL+wYQB7UN4=";

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
