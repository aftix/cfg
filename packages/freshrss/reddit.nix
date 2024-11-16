{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
  lib,
}:
stdenvNoCC.mkDerivation (self: {
  pname = "freshrss-extensions-reddit-image";
  version = "brach";

  src = fetchFromGitHub {
    owner = "aledeg";
    repo = "xExtension-RedditImage";
    rev = "b2aaf6bcf56f60c937dc157cf0f5c6b0fa41f784";
    hash = "sha256-H/uxt441ygLL0RoUdtTn9Q6Q/Ois8RHlhF8eLpTza4Q=";
  };

  installPhase = import ./toplevel-ext.nix self.src "RedditImage";

  passthru.updateScript = nix-update-script {};

  meta = with lib; {
    homepage = "https://github.com/aledeg/xExtension-RedditImage";
    license = licenses.agpl3Only;
  };
})
