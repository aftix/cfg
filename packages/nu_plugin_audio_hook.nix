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
  version = "8c9290301e672bddef77f6c92c5929144c2f7c5e";

  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = pname;
    rev = version;
    sha256 = "sha256-5iCZWNZ1j5AdVSFyiGJ/85pkyRWV7fjFd95LMopeuZ0=";
  };
  cargoHash = "sha256-ga6c4M8iLJ3graKK4i+W/WderIFOmeBazruqsREQQso=";

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
