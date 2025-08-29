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
  nix-update-script,
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
      outputHash = "sha256-/xAY1q6i8vhE0KjK5a0H4D6SFr4wHMQttZDRitzPqtI=";
    };
  in {
    pname = "YouTube-operational-API";
    version = "0-unstable-2025-08-25";

    src = fetchFromGitHub {
      inherit owner;
      repo = self.pname;
      rev = "527c60cc9dd9d5d0086e7ec5022e81e98054574f";
      hash = "sha256-iYuj1gSJX/Yv2dcqKKClpAqREFs5WEfW8Nc6aN7kpKg=";
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

    passthru.updateScript = nix-update-script {
      extraArgs = ["--version" "branch"];
    };

    meta = {
      description = "YouTube operational API works when YouTube Data API v3 fails.";
      homepage = "https://github.com/${owner}/${self.pname}";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux;
    };
  })
