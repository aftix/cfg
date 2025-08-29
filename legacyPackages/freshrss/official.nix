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
  version = "0-unstable-2025-08-26";

  src = fetchFromGitHub {
    owner = "FreshRSS";
    repo = "Extensions";
    rev = "d4a7cec568720b7103e19362197d6dcc097f72c4";
    hash = "sha256-ZnCu2QtuhDlHLHGlxF9vDv90QSxzYOScL233A/Hrp7Q=";
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
