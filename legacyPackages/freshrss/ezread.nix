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
  version = "1.1.5-unstable-2025-09-19";

  src = fetchFromGitHub {
    owner = "kalvn";
    repo = "freshrss-mark-previous-as-read";
    rev = "1079f7ee542059e9d12c3a46e19790c4540006aa";
    hash = "sha256-O8cXRXp3slj4caBDwMLnLbw8sT+ouPercCE7s9eLADU=";
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
