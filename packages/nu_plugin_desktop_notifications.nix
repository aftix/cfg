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
  version = "0.111.0-unstable-2026-03-05";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "241642cbff0c29f338efdd7b9c2ee8787aaff26f";
    sha256 = "sha256-fWLgDq2DJm+KReMR9JmkXbz8HGHcL2Ps3emwAQOYgyE=";
  };
  cargoHash = "sha256-UjH0CBzRNdUu+S8RKCMI/7XRmiFT9U9iuNcu1jWgflc=";

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
