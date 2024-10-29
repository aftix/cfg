{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
  lib,
}:
stdenvNoCC.mkDerivation (self: {
  pname = "freshrss-extensions-ezread";
  version = "0-unstable-2024-05-25";

  src = fetchFromGitHub {
    owner = "kalvn";
    repo = "freshrss-mark-previous-as-read";
    rev = "53be867476bcf174a90fcd23edac975cb251a742";
    hash = "sha256-9Ra7FVYJuMdW1+W19KbHxb91MWiJe1mICDYXr11DBe8=";
  };

  installPhase = import ./with-subdirs.nix self.src;

  passthru.updateScript = nix-update-script {};

  meta = with lib; {
    homepage = "https://github.com/kalvn/freshrss-mark-previous-as-read";
    license = licenses.gpl2Only;
  };
})
