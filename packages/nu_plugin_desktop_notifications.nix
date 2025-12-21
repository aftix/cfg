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
  version = "0.109.1-unstable-2025-12-21";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "0d1c260abdf33c1d5f627d664671f0a16bc5b69b";
    sha256 = "sha256-tEAE9jxQov1jECYfP0hYmlgAqzRKK3pYSkPplfGYUbA=";
  };
  cargoHash = "sha256-B9n8tBlDHDNYA0/4sIjVKiVYguQ0X61lClA0+/HyKSE=";

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
