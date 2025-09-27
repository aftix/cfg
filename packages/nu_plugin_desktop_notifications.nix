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
  version = "0.107.0-unstable-2025-09-27";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "b924b1340998c2f39ace11952dbe1af1da732ae9";
    sha256 = "sha256-lPL0Wbru7kWCVNTbMkNtvOyqDMqHNBrcooCurf1ip18=";
  };
  cargoHash = "sha256-tvZrU/iyAAntIa889YmP1/y8YsXf9osBMPD5ZENZngk=";

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
