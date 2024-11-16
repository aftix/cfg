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
  version = "6fde8d3a232bff33b8985ccfdf5018834f58d7ac";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = version;
    sha256 = "sha256-tGn6VdiCl2ZpSzQTVKqHo+6lLDhjhPnY3KTanS+Sf8g=";
  };
  cargoHash = "sha256-66Uggf7AMJt0uLOlCf7S1VotoHfhFeLAE0JmUZjdbVQ=";

  nativeBuildInputs = [pkg-config] ++ lib.optionals stdenv.cc.isClang [rustPlatform.bindgenHook];
  buildInputs = [alsa-lib];
  buildFeatures = ["all-decoders"];

  meta = with lib; {
    description = "A nushell plugin to make and play sounds";
    mainProgram = "nu_plugin_audio_hook";
    homepage = "https://github.com/FMotalleb/nu_plugin_audio_hook";
    license = licenses.mit;
    platforms = with platforms; linux;
  };
}
