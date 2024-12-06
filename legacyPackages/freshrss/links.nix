{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
  lib,
}:
stdenvNoCC.mkDerivation (self: {
  pname = "freshrss-extensions-kapdap";
  version = "brach";

  src = fetchFromGitHub {
    owner = "kapdap";
    repo = "freshrss-extensions";
    rev = "a44a25a6b8c7f298ac05b8db323bdea931e6e530";
    hash = "sha256-uWZi0sHdfDENJqjqTz5yoDZp3ViZahYI2OUgajdx4MQ=";
  };

  installPhase = import ./with-subdirs.nix self.src;

  passthru.updateScript = nix-update-script {};

  meta = with lib; {
    homepage = "https://github.com/kapdap/freshrss-extensions";
    license = licenses.mit;
  };
})
