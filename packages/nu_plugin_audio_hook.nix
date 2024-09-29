{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  alsa-lib,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_audio_hook";
  version = "2f778866fa580367000b7125d66cef4940e4f931";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = version;
    sha256 = "sha256-gZv9FNnKe6AoT6xAbaK5VfWleQnimKU67HcPvTbuo8g=";
  };
  cargoHash = "sha256-5oz9f9g15MsoFFb36AewQVSrAM+w3suv+4J7J2PSC+g=";

  nativeBuildInputs = [pkg-config] ++ lib.optionals stdenv.cc.isClang [rustPlatform.bindgenHook];
  buildInputs = [alsa-lib];
  buildFeatures = ["all-decoders"];

  meta = with lib; {
    description = "A nushell plugin to make and play sounds";
    mainProgram = "nu_plugin_audio_hook";
    homepage = "https://github.com/FMotalleb/nu_plugin_audio_hook/tree/${version}";
    license = licenses.mit;
    platforms = with platforms; all;
  };
}
