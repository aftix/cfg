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
  version = "0-unstable-2025-06-03";

  src = fetchFromGitHub {
    owner = "FreshRSS";
    repo = "Extensions";
    rev = "1126dfe7e925f085bde9e14e17c82934d59c3d36";
    hash = "sha256-/NdnSWQGx6cbIW5RDmyogodXV4UHtLFX99ztdjrGJLs=";
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
