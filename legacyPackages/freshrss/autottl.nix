# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
  lib,
}:
stdenvNoCC.mkDerivation (self: {
  pname = "freshrss-extensions-autottl";
  version = "0.5.8";

  src = fetchFromGitHub {
    owner = "mgnsk";
    repo = "FreshRSS-AutoTTL";
    rev = "3bf43ca057f7efb57deca1ddb4f7ad0a8cf11bae";
    hash = "sha256-pLuGwwlowLWHlY5V3jiN84rCzUxn/QUTkUMMc6+C3HM=";
  };

  installPhase = import ./toplevel-ext.nix self.src "AutoTTL";

  passthru.updateScript = nix-update-script {};

  meta = {
    homepage = "https://github.com/mgnsk/FreshRSS-AutoTTL";
    license = lib.licenses.agpl3Only;
  };
})
