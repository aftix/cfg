{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
  lib,
}:
stdenvNoCC.mkDerivation (self: {
  pname = "freshrss-extensions-latexsupport";
  version = "brach";

  src = fetchFromGitHub {
    owner = "aledeg";
    repo = "xExtension-LatexSupport";
    rev = "c3e8a5961e47da53d112522e27586f7734b265d0";
    hash = "sha256-DvL5tyj0FHVCL9ZcBSLuZ01shB448WDVpQmgkYLhoLs=";
  };

  installPhase = import ./toplevel-ext.nix self.src "LatexSupport";

  passthru.updateScript = nix-update-script {};

  meta = with lib; {
    homepage = "https://github.com/aledeg/xExtension-LatexSupport";
    license = licenses.agpl3Only;
  };
})
