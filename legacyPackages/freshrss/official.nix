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
  pname = "freshrss-extensions-official";
  version = "0-unstable-2025-08-01";

  src = fetchFromGitHub {
    owner = "FreshRSS";
    repo = "Extensions";
    rev = "a5309b51fe3c2cf0ca86689365b855d37f85b35b";
    hash = "sha256-wajyPqfUxteACUSoAzStwAc4dctoe4B0Ad1/yQhGxe4=";
  };

  installPhase = import ./with-subdirs.nix self.src;

  passthru.updateScript = nix-update-script {};

  meta = with lib; {
    description = "Repository containing all the official FreshRSS extensions";
    homepage = "https://github.com/FreshRSS/Extensions";
    license = licenses.agpl3Only;
    updateVersion = "branch";
  };
})
