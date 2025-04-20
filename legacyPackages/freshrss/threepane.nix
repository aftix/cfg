{
  stdenvNoCC,
  fetchFromGitLab,
  nix-update-script,
  lib,
}:
stdenvNoCC.mkDerivation (self: {
  pname = "freshrss-extensions-threepane";
  version = "1.11-unstable-2024-12-02";

  src = fetchFromGitLab {
    domain = "framagit.org";
    owner = "nicofrand";
    repo = "xextension-threepanesview";
    rev = "cf24f7330ae509136a38f83a22f087c35f3bb9c5";
    hash = "sha256-rv5A01QNacjGRSw/fBkrvV4HveD90T9n06QeAe7blMw=";
  };

  installPhase = import ./toplevel-ext.nix self.src "threepanesview";

  passthru.updateScript = nix-update-script {};

  meta = with lib; {
    homepage = "https://framagit.org/nicofrand/xextension-threepanesview";
    license = licenses.mit;
  };
})
