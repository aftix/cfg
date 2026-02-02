# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  stdenvNoCC,
  fetchFromGitLab,
  nix-update-script,
  lib,
}:
stdenvNoCC.mkDerivation (self: {
  pname = "freshrss-extensions-threepane";
  version = "1.11-unstable-2025-12-31";

  src = fetchFromGitLab {
    domain = "framagit.org";
    owner = "nicofrand";
    repo = "xextension-threepanesview";
    rev = "6b53dcaae5fba3ec26f6feb90427e832afd5044d";
    hash = "sha256-An30uyTx4j3N/qgxhmRCU6XxhtB7SLzXJNmGasaY/Hg=";
  };

  installPhase = import ./toplevel-ext.nix self.src "threepanesview";

  passthru.updateScript = nix-update-script {
    extraArgs = ["--version" "branch"];
  };

  meta = {
    homepage = "https://framagit.org/nicofrand/xextension-threepanesview";
    license = lib.licenses.mit;
  };
})
