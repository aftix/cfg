{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
  lib,
}:
stdenvNoCC.mkDerivation (self: {
  pname = "freshrss-extensions-autottl";
  version = "0.5.8";

  src = fetchFromGitHub {
    owner = "mgnsk";
    repo = "FreshRSS-AutoTTL";
    rev = "3bf43ca057f7efb57deca1ddb4f7ad0a8cf11bae";
    hash = "sha256-pLuGwwlowLWHlY5V3jiN84rCzUxn/QUTkUMMc6+C3HM=";
  };

  installPhase = import ./toplevel-ext.nix self.src "AutoTTL";

  passthru.updateScript = nix-update-script {};

  meta = with lib; {
    homepage = "https://github.com/mgnsk/FreshRSS-AutoTTL";
    license = licenses.agpl3Only;
  };
})
