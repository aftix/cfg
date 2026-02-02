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
  version = "master-unstable-2026-02-01";

  src = fetchFromGitHub {
    owner = "FreshRSS";
    repo = "Extensions";
    rev = "1c834233048f02985035c673aaf1e3af534fcd66";
    hash = "sha256-Vd27vkERGo1783SVbghQI85qZFro51DppTnctZOsa/Y=";
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
