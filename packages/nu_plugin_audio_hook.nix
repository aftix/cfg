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
  version = "9a7d7d23d0aeffa11a154887541dcde17344d763";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = version;
    sha256 = "sha256-Fw/cH2GgmWaNGkZ67nDwr2u4ujFOjQV5T6AbdY0oIyc=";
  };
  useFetchCargoVendor = true;
  cargoHash = "sha256-Oa3NkVQVE94QXA5zNeXlcdoahJ51CmmIbmOIl+55xzw=";

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
