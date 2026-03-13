# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  stdenvNoCC,
  fetchFromGitHub,
  lix-update-script,
  lib,
}:
stdenvNoCC.mkDerivation (self: {
  pname = "freshrss-extensions-ezread";
  version = "1.1.6-unstable-2026-03-11";

  src = fetchFromGitHub {
    owner = "kalvn";
    repo = "freshrss-mark-previous-as-read";
    rev = "cbcf7080e4df16941fab248bbd561516c0382246";
    hash = "sha256-HI24lz6ga4iGRLvB84kJkD8ZCBA1c7UsMgmzkSLXva4=";
  };

  installPhase = import ./with-subdirs.nix self.src;

  passthru.updateScript = lix-update-script {
    extraArgs = ["--version" "branch"];
  };

  meta = {
    homepage = "https://github.com/kalvn/freshrss-mark-previous-as-read";
    license = lib.licenses.gpl2Only;
  };
})
