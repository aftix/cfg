# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  lib,
  stdenv,
  nginxBlacklist,
}:
stdenv.mkDerivation {
  pname = "nginx-ultimate-bad-bot-blocker";
  version = "1";

  src = nginxBlacklist;

  installPhase = ''
    mkdir -p "$out"
    cp -R *.d "$out/."
  '';

  meta = {
    description = "nginx ultimate bad bot blocker";
    homepage = "https://github.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker";
    license = lib.licenses.mit;
    updateVersion = "none";
  };
}
