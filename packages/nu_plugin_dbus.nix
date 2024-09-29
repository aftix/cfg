{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  dbus,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_dbus";
  version = "0.11.0";

  src = fetchFromGitHub {
    owner = "devyn";
    repo = pname;
    rev = "refs/tags/${version}";
    sha256 = "sha256-pOgPlvsE8h/WtvLMcLz34hNlZQf60CCAavi+isV2jnU=";
  };
  cargoHash = "sha256-HoJDKqFO2kwCRl2+8DcovI9bIylQl3HfcAfatBIww1Q=";

  nativeBuildInputs = [pkg-config] ++ lib.optionals stdenv.cc.isClang [rustPlatform.bindgenHook];
  buildInputs = [dbus];

  meta = with lib; {
    description = "Nushell plugin for communicating with D-Bus";
    mainProgram = "nu_plugin_dbus";
    homepage = "https://github.com/devyn/nu_plugin_dbus/tree/${version}";
    license = licenses.mit;
    platforms = with platforms; linux;
  };
}
