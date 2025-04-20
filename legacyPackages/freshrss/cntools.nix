{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
  lib,
}:
stdenvNoCC.mkDerivation (self: {
  pname = "freshrss-extensions-cntools";
  version = "0-unstable-2024-11-14";

  src = fetchFromGitHub {
    owner = "cn-tools";
    repo = "cntools_FreshRssExtensions";
    rev = "878fb05675a90ddb8ab308b472ad2139d5725de8";
    hash = "sha256-tKe2Ix+VE56p5zkjfsdU9AiRw3s4jDoJJufYXci6jdY=";
  };

  installPhase = import ./with-subdirs.nix self.src;

  passthru.updateScript = nix-update-script {};

  meta = with lib; {
    homepage = "https://github.com/cn-tools/cntools_FreshRssExtensions";
    license = licenses.mit;
  };
})
