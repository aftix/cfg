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
      outputHash = "sha256-brerQn0L+tyBLB1QKnDHP9BJI12V+AQcBcpCdxh8Ihs=";
    };
  in {
    pname = "YouTube-operational-API";
    version = "0-unstable-2025-09-09";

    src = fetchFromGitHub {
      inherit owner;
      repo = self.pname;
      rev = "0d2768a5fcf560288eb3a9fa573056bdd5dba3d2";
      hash = "sha256-WzSZkLupCTqOpyAzj4UeAbWPSWn3EQoiC5KqkLWzxgc=";
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
