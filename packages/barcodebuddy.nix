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
        redis
        sockets
      ]);
  };
in
  stdenvNoCC.mkDerivation (self: {
    pname = "barcodebuddy";
    version = "1.8.1.8";

    src = fetchFromGitHub {
      owner = "Forceu";
      repo = "barcodebuddy";
      rev = "v${self.version}";
      hash = "sha256-zHprV5mCFciq5XgJD7fmEgb/vHlwAWOY1TcdBoCA8Eo=";
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
    };
  })
