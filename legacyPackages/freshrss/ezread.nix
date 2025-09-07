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
  version = "1.1.3-unstable-2025-08-31";

  src = fetchFromGitHub {
    owner = "kalvn";
    repo = "freshrss-mark-previous-as-read";
    rev = "96882240bdd33c7aaa58d041a8982c215f62da1d";
    hash = "sha256-hF46jkQuV2fYr+8bbUEA/W+r7yvDXjseRfBkA4VuQHo=";
  };

  installPhase = import ./with-subdirs.nix self.src;

  passthru.updateScript = nix-update-script {
    extraArgs = ["--version" "branch"];
  };

  meta = {
    homepage = "https://github.com/kalvn/freshrss-mark-previous-as-read";
    license = lib.licenses.gpl2Only;
  };
})
