# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  lib,
  rustPlatform,
  fetchFromGitHub,
  lix-update-script,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_desktop_notifications";
  version = "0.112.2-unstable-2026-04-29";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "8afadf93bc9905b40eaf2f389cab0f8e58fc2027";
    sha256 = "sha256-zh6gmG4+ZIkWL8i0mO6jzMj6RdIxdGraN1LoQkCAxZc=";
  };
  cargoHash = "sha256-p2b/kZCP9zOuKNYVt/fMJoN5Z5wEYJ6zn44qV86YIQg=";

  passthru.updateScript = lix-update-script {
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
