{
  rustPlatform,
  fetchFromSourcehut,
  lib,
  nix-update-script,
  pkg-config,
  glib,
  gexiv2,
}:
rustPlatform.buildRustPackage rec {
  pname = "coffeepaste";
  version = "1.5.1";

  src = fetchFromSourcehut {
    domain = "sr.ht";
    owner = "~mort";
    repo = "coffeepaste";
    rev = "92795c856c6227d334635538d5176f6fe34de988";
    hash = "sha256-zsdLUdTiqnnYRe17HndoAfOWGGB08UBsXP6A7FpG1Sc=";
  };
  cargoLock.lockFile = "${src}/Cargo.lock";

  buildInputs = [glib gexiv2];
  nativeBuildInputs = [pkg-config];

  patches = [./change-url-replace.patch];
  passthru.updateScript = nix-update-script {};

  meta = with lib; {
    description = "A neat pastebin";
    mainProgram = "coffeepaste";
    homepage = "https://git.sr.ht/~mort/coffeepaste";
    license = licenses.agpl3Only;
  };
}
