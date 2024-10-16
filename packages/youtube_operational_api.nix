{
  stdenvNoCC,
  lib,
  fetchFromGitHub,
  findutils,
  protobuf_27,
}: let
  owner = "Benjamin-Loison";
in
  stdenvNoCC.mkDerivation (self: {
    pname = "YouTube-operational-API";
    version = "88443c44f8de2d312e549c00647977a4358e94f7";

    src = fetchFromGitHub {
      inherit owner;
      repo = self.pname;
      rev = self.version;
      sha256 = "sha256-2ZpafHUPeTHpe6CKtU0GiW1LDqTjEOMNOILzmb8Uu0M=";
    };

    buildInputs = [protobuf_27 findutils];

    buildPhase = ''
      runHook preBuild
      protoc --php_out=proto/php/ --proto_path=proto/prototypes/ $(find proto/prototypes/ -type f)
      runHook postBuild
    '';

    postPatch = ''
      patchShebangs --host tools/*.py
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -vr * $out/
      runHook postInstall
    '';

    meta = with lib; {
      description = "YouTube operational API works when YouTube Data API v3 fails.";
      homepage = "https://github.com/${owner}/${pname}/tree/${version}";
      license = licenses.mit;
      platforms = with platforms; linux;
    };
  })
