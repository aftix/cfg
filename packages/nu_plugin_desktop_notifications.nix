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
  version = "0.111.0-unstable-2026-03-09";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "14b29f495c66f4b7da02659dcfd51c186e6e334c";
    sha256 = "sha256-9qCUJpv9e8kkOTFe93FBwSFPmH0E8glBfSQaDMwb8c8=";
  };
  cargoHash = "sha256-9h6GC1ZEXbR2ScdKO8g+MgPHIF7TFD0vnklUR7wcxM8=";

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
