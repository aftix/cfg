{
  php,
  stdenvNoCC,
  lib,
  fetchFromGitHub,
  findutils,
  protobuf_27,
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
    version = "0-unstable-2025-02-08";

    src = fetchFromGitHub {
      inherit owner;
      repo = self.pname;
      rev = "d1b79acfe2c8569f54d478b25ebcba650512488b";
      hash = "sha256-8bHk6Qvuq4UNZXi0EjirVMurcBgItzOLLTLWYbxFKiQ=";
    };

    buildInputs = [protobuf_27 findutils php vendorSrc];

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
    };
  })
