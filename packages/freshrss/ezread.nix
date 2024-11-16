{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
  lib,
}:
stdenvNoCC.mkDerivation (self: {
  pname = "freshrss-extensions-ezread";
  version = "brach";

  src = fetchFromGitHub {
    owner = "kalvn";
    repo = "freshrss-mark-previous-as-read";
    rev = "29126310aeeb3c12b47b8696d8475f27dd5771e0";
    hash = "sha256-1VQBdN0rS8WojobZ19jOjbDl9ec5z38e/nZIi9N27qo=";
  };

  installPhase = import ./with-subdirs.nix self.src;

  passthru.updateScript = nix-update-script {};

  meta = with lib; {
    homepage = "https://github.com/kalvn/freshrss-mark-previous-as-read";
    license = licenses.gpl2Only;
  };
})
