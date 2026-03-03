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
  version = "0.111.0-unstable-2026-03-01";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "7e94dffc86970e2de2892bac61a191426d75d34f";
    sha256 = "sha256-hcjJa+Y0N7QgVpxc/OJYCpYaZ6FLQiabvk7RLUjhZAI=";
  };
  cargoHash = "sha256-nDRu9gaJGfuCKMgBptZPS5ANaPwKJ7BGAe10QI8skRM=";

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
