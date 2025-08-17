# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  php,
  stdenvNoCC,
  lib,
  fetchFromGitHub,
  nix-update-script,
  valkey,
  evtest,
}: let
  phpWithExts = php.buildEnv {
    extensions = {
      enabled,
      all,
    }:
      enabled
      ++ (with all; [
        curl
        mbstring
        sqlite3
        valkey
        sockets
      ]);
  };
in
  stdenvNoCC.mkDerivation (self: {
    pname = "barcodebuddy";
    version = "1.8.1.8-unstable-2025-01-10";

    src = fetchFromGitHub {
      owner = "Forceu";
      repo = "barcodebuddy";
      rev = "ea425e19b29c788640133dfccee10f869e5c6b1a";
      hash = "sha256-UwSF6lpYoEW583GcpJsasvGYfF2ad0GcySJGrPKETgA=";
    };

    nativeBuildInputs = [
      phpWithExts
      valkey
      evtest
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"
      cp -vR "${self.src}/"* "$out/"

      runHook postInstall
    '';

    passthru = {
      inherit phpWithExts;
      updateScript = nix-update-script {};
    };

    meta = with lib; {
      description = "Create barcodes with information for Grocy";
      homepage = "https://github.com/Forceu/barcodebuddy";
      licenes = licenses.agpl3Only;
      updateVersion = "branch";
    };
  })
