{
  stdenvNoCC,
  fetchFromGitLab,
  nix-update-script,
  lib,
}:
stdenvNoCC.mkDerivation (self: {
  pname = "freshrss-extensions-threepane";
  version = "0-unstable-2024-03-30";

  src = fetchFromGitLab {
    domain = "framagit.org";
    owner = "nicofrand";
    repo = "xextension-threepanesview";
    rev = "3863ec5e3c0acdc33f0378cb8985b20dc9c810b7";
    hash = "sha256-3dva36Wgia3/qJB1tH/7trja7KFY9DVrnCQwD6/dNPs=";
  };

  installPhase = import ./toplevel-ext.nix self.src "threepanesview";

  passthru.updateScript = nix-update-script {};

  meta = with lib; {
    homepage = "https://framagit.org/nicofrand/xextension-threepanesview";
    license = licenses.mit;
  };
})
