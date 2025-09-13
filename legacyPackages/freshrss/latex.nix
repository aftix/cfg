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
  pname = "freshrss-extensions-latexsupport";
  version = "0.1.5-unstable-2025-09-11";

  src = fetchFromGitHub {
    owner = "aledeg";
    repo = "xExtension-LatexSupport";
    rev = "d98fc56a7a12f04a913beea9a8ee81e463ad1b92";
    hash = "sha256-pk4E7xl5DqujJxHiMuNO9m144As+F+9lii47nYWZbLc=";
  };

  installPhase = import ./toplevel-ext.nix self.src "LatexSupport";

  passthru.updateScript = nix-update-script {
    extraArgs = ["--version" "branch"];
  };

  meta = {
    homepage = "https://github.com/aledeg/xExtension-LatexSupport";
    license = lib.licenses.agpl3Only;
  };
})
