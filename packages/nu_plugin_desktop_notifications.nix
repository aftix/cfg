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
  version = "0.106.1-unstable-2025-08-01";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = "df62f36b34098c8060b5d86904368123603da094";
    sha256 = "sha256-7ROby3TwpgCkEtMLeLNts6vG/XV6hBpUJHtiUJMXcoM=";
  };
  cargoHash = "sha256-54GkHmvKLhYD49bgis2cYWAcelyzTUqf0pEqQJK5/8c=";

  meta = with lib; {
    description = "A nushell plugin to send desktop notifications.";
    mainProgram = "nu_plugin_desktop_notifications";
    homepage = "https://github.com/FMotalleb/nu_plugin_desktop_notifications";
    license = licenses.mit;
    platforms = platforms.linux;
    updateVersion = "branch";
  };
}
