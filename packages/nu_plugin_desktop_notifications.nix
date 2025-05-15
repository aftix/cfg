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
  version = "1.2.4-unstable-2025-05-05";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "de4464bf6ce6503977ee2bd41f11aeabc49214aa";
    sha256 = "sha256-ZQ1zOYcGTfHhRAnDxVxcZ740yF2nccIOWL+yuShhs0Y=";
  };
  useFetchCargoVendor = true;
  cargoHash = "sha256-DrHWdwljPsPkzbM9mok5x7gn6Op1ytwg67+HtcZg8G8=";

  meta = with lib; {
    description = "A nushell plugin to send desktop notifications.";
    mainProgram = "nu_plugin_desktop_notifications";
    homepage = "https://github.com/FMotalleb/nu_plugin_desktop_notifications";
    license = licenses.mit;
    platforms = platforms.linux;
    updateVersion = "branch";
  };
}
