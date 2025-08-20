# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  php,
  stdenvNoCC,
  lib,
  fetchFromGitHub,
  findutils,
  protobuf_29,
}: let
  owner = "Benjamin-Loison";
in
  stdenvNoCC.mkDerivation (self: let
    vendorSrc = stdenvNoCC.mkDerivation {
      inherit (self) src version;
      pname = "${self.pname}-vendor";

      buildInputs = [php.packages.composer];

      patches = [./composer.patch];

      buildPhase = ''
        runHook preBuild
        composer install
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        mkdir $out
        cp -vr vendor/* $out/
        runHook postInstall
      '';

      doCheck = false;

      outputHashAlgo = "sha256";
      outputHashMode = "recursive";
      outputHash = "sha256-ws6l6Ko8DT+mr0XEbY+TUFHT2t6g9Zgxny4gTDE0MGA=";
    };
  in {
    pname = "YouTube-operational-API";
    version = "0-unstable-2025-08-18";

    src = fetchFromGitHub {
      inherit owner;
      repo = self.pname;
      rev = "6750e3dfc0e3871196f561db935a3576bf6640de";
      hash = "sha256-rZI1t2eyEnKzQR9NmoHV93LK9XvlRysXg0+bVTEs2m0=";
    };

    buildInputs = [protobuf_29 findutils php vendorSrc];

    postPatch = ''
      patchShebangs --host tools/*.py
    '';

    buildPhase = ''
      runHook preBuild
      protoc --php_out=proto/php/ --proto_path=proto/prototypes/ $(find proto/prototypes/ -type f)
      mkdir vendor
      cp -vr "${vendorSrc}"/* vendor/
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir $out
      cp -vr * $out/
      runHook postInstall
    '';

    meta = with lib; {
      description = "YouTube operational API works when YouTube Data API v3 fails.";
      homepage = "https://github.com/${owner}/${self.pname}";
      license = licenses.mit;
      platforms = platforms.linux;
      updateVersion = "branch";
    };
  })
