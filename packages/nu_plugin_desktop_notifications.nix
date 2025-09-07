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
  version = "0.107.0-unstable-2025-09-07";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "cacfd2566a9a49744728b9984d88679681874c00";
    sha256 = "sha256-KySh9eR090VebuHgO6Mi720wB2l9HwKj9eKCbG3vMQ4=";
  };
  cargoHash = "sha256-ZBZ6V9NTZGq6A/XSxi/pgrzsQYe46q6phx9WfT/b2vw=";

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
