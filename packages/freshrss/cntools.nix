{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
  lib,
}:
stdenvNoCC.mkDerivation (self: {
  pname = "freshrss-extensions-cntools";
  version = "0-unstable-2024-08-18";

  src = fetchFromGitHub {
    owner = "cn-tools";
    repo = "cntools_FreshRssExtensions";
    rev = "4860d96e8cc46a1baba6b1b0588dc6f9d6b400e5";
    hash = "sha256-1YLAhCsEymPmNZAGKrvGM+4Bfy8WeDWQVEM3JUKsyqY=";
  };

  installPhase = import ./with-subdirs.nix self.src;

  passthru.updateScript = nix-update-script {};

  meta = with lib; {
    homepage = "https://github.com/cn-tools/cntools_FreshRssExtensions";
    license = licenses.mit;
  };
})
