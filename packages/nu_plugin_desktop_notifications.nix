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
  version = "0.107.0-unstable-2025-10-07";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "380d2727e1dc4597b7dee9c776ff6704626832ac";
    sha256 = "sha256-+8hpwzUnuCwrKMBawHZuv8QYRWH2m+1lTJ2t751f6jo=";
  };
  cargoHash = "sha256-TNHDdt8B7olO1jdUqWqbw5Uz7p6Owz4YvfiSjR5Rbfs=";

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
