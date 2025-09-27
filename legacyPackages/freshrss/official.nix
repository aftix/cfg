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
  version = "0-unstable-2025-09-25";

  src = fetchFromGitHub {
    owner = "FreshRSS";
    repo = "Extensions";
    rev = "2a7c33bf13e9d7a2561ab5548bcec0bc1f9501c7";
    hash = "sha256-ZLDGqYuCx1XgpIPh1tZ1qxLPY6aRd3IIGh8MjBLsnA8=";
  };

  installPhase = import ./with-subdirs.nix self.src;

  passthru.updateScript = nix-update-script {
    extraArgs = ["--version" "branch"];
  };

  meta = {
    description = "Repository containing all the official FreshRSS extensions";
    homepage = "https://github.com/FreshRSS/Extensions";
    license = lib.licenses.agpl3Only;
  };
})
