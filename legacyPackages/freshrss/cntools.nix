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
  pname = "freshrss-extensions-cntools";
  version = "0-unstable-2026-01-30";

  src = fetchFromGitHub {
    owner = "cn-tools";
    repo = "cntools_FreshRssExtensions";
    rev = "ae40a34e260e0609e49d1a338e42284383e9703b";
    hash = "sha256-4103QhVRWVe4HYbReX/qPA4KwtHZ5AsAxwpX9hQMwCw=";
  };

  installPhase = import ./with-subdirs.nix self.src;

  passthru.updateScript = nix-update-script {
    extraArgs = ["--version" "branch"];
  };

  meta = {
    homepage = "https://github.com/cn-tools/cntools_FreshRssExtensions";
    license = lib.licenses.mit;
  };
})
