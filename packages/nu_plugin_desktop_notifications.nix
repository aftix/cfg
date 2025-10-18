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
  version = "0.108.0-unstable-2025-10-17";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "2580e7d2d0c725e15f8aa803178ed8083f4cbd36";
    sha256 = "sha256-9NkWPoTdMxFlI/BkP8w0ltC6UVh3/tg9gjwBuS3k/Cg=";
  };
  cargoHash = "sha256-GK6ytH/SDHh6GlLrSA2oJLza1tvYOUp4cR5CM6bloz8=";

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
