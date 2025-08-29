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
  pname = "freshrss-extensions-ezpriorities";
  version = "0-unstable-2025-08-07";

  src = fetchFromGitHub {
    owner = "aidistan";
    repo = "freshrss-extensions";
    rev = "ca78729c8717881158fe3b9a49a824a78f822575";
    hash = "sha256-RxmQnzYLT+S2IOfPoLwhEi7gqUQOxqTAQ0A+ynOoEvk=";
  };

  installPhase = import ./with-subdirs.nix self.src;

  passthru.updateScript = nix-update-script {
    extraArgs = ["--version" "branch"];
  };

  meta = {
    homepage = "https://github.com/aidistan/freshrss-extensions";
    license = lib.licenses.mit;
  };
})
