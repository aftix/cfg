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
  version = "0.110.0-unstable-2026-02-01";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "56655c2083e9e021e43fe4f69c0f5ace99a7235c";
    sha256 = "sha256-vs05Th4XkoxTpUI8BEOR3kbT7q8gRxjuFvvhXedfaZY=";
  };
  cargoHash = "sha256-0cORcqndEUuP60pVGFb0Yvg+TO5w/B8+4zw6s5ZZxqM=";

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
