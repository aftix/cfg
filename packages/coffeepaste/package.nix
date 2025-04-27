# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  rustPlatform,
  fetchzip,
  lib,
  nix-update-script,
  pkg-config,
  glib,
  gexiv2,
}:
rustPlatform.buildRustPackage rec {
  pname = "coffeepaste";
  version = "2.0.0";

  src = fetchzip {
    url = "https://git.sr.ht/~mort/coffeepaste/archive/v${version}.tar.gz";
    hash = "sha256-2SH20Iw6Y159NBAu//wudoP/ufl8Ayy4F7UQdSoR41c=";
  };
  useFetchCargoVendor = true;
  cargoHash = "sha256-ymD5SCUpIBHGx2ViOPJfZGFPEdev4VMfllkkTZUNKz8=";

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
