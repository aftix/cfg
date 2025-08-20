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
  pname = "freshrss-extensions-ezread";
  version = "1.1.2-unstable-2025-03-27";

  src = fetchFromGitHub {
    owner = "kalvn";
    repo = "freshrss-mark-previous-as-read";
    rev = "929df0badcbbb333cc70af25c1b7961dd284234c";
    hash = "sha256-xsPtrpscYorVAWokBCK7VhHG1FmjYApvC0/pG+c6X24=";
  };

  installPhase = import ./with-subdirs.nix self.src;

  passthru.updateScript = nix-update-script {};

  meta = {
    homepage = "https://github.com/kalvn/freshrss-mark-previous-as-read";
    license = lib.licenses.gpl2Only;
    updateVersion = "branch";
  };
})
