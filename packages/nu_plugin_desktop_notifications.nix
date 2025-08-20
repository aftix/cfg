# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_desktop_notifications";
  version = "0.106.1-unstable-2025-08-17";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "b752d938075edd76da011252baf3a3ff2a715d50";
    sha256 = "sha256-frp3IDFe63Nyck2LZeAZl5hHA+8VVggvrQaMon1pXmQ=";
  };
  cargoHash = "sha256-XVH75ZtFAv7mCa37EqgouKa39+vxoXhodESb3yDHDfk=";

  meta = {
    description = "A nushell plugin to send desktop notifications.";
    mainProgram = "nu_plugin_desktop_notifications";
    homepage = "https://github.com/FMotalleb/nu_plugin_desktop_notifications";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    updateVersion = "branch";
  };
}
