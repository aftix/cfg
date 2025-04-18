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
      outputHash = "sha256-BW9f07oGbHhg7mEnz1oCHiXts9dKIxa/3ijH2o+xty8=";
    };
  in {
    pname = "YouTube-operational-API";
    version = "0e6889ec5d77f2e739dd86156c5c90c2d5100a06";

    src = fetchFromGitHub {
      inherit owner;
      repo = self.pname;
      rev = self.version;
      hash = "sha256-xBj+SN2ZXohD0keW58yThB02YVujtDj3Krjy22/JGso=";
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
      platforms = with platforms; linux;
    };
  })
