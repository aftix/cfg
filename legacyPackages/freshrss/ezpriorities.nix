{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
  lib,
}:
stdenvNoCC.mkDerivation (self: {
  pname = "freshrss-extensions-ezpriorities";
  version = "brach";

  src = fetchFromGitHub {
    owner = "aidistan";
    repo = "freshrss-extensions";
    rev = "ed569b32c31080d2f8f77a67fc6e3da0e7b7aebf";
    hash = "sha256-FOhVZLsdRY1LszT7YlYV70WUQUelyj1uY9d3h7eTX4w=";
  };

  installPhase = import ./with-subdirs.nix self.src;

  passthru.updateScript = nix-update-script {};

  meta = with lib; {
    homepage = "https://github.com/aidistan/freshrss-extensions";
    license = licenses.mit;
  };
})
