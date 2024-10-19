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
  version = "0.12.0";

  src = fetchFromGitHub {
    owner = "devyn";
    repo = pname;
    rev = "refs/tags/${version}";
    sha256 = "sha256-I6FB2Hu/uyA6lBGRlC6Vwxad7jrl2OtlngpmiyhblKs=";
  };
  cargoHash = "sha256-WwdeDiFVyk8ixxKS1v3P274E1wp+v70qCk+rNEpoce4=";

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
