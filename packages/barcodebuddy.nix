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
    version = "1.8.1.8-unstable-2024-06-02";

    src = fetchFromGitHub {
      owner = "Forceu";
      repo = "barcodebuddy";
      rev = "369798d05395ed055ea4b9b03d96471b784ed106";
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
