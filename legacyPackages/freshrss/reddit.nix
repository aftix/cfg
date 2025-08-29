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
  pname = "freshrss-extensions-reddit-image";
  version = "1.2.0-unstable-2024-01-11";

  src = fetchFromGitHub {
    owner = "aledeg";
    repo = "xExtension-RedditImage";
    rev = "b2aaf6bcf56f60c937dc157cf0f5c6b0fa41f784";
    hash = "sha256-H/uxt441ygLL0RoUdtTn9Q6Q/Ois8RHlhF8eLpTza4Q=";
  };

  installPhase = import ./toplevel-ext.nix self.src "RedditImage";

  passthru.updateScript = nix-update-script {
    extraArgs = ["--version" "branch"];
  };

  meta = {
    homepage = "https://github.com/aledeg/xExtension-RedditImage";
    license = lib.licenses.agpl3Only;
  };
})
