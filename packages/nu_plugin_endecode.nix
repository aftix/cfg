{
  lib,
  rustPlatform,
  fetchFromGitea,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_endecode";
  version = "9d8d29ae40734ad95765f780b245d54ce7a291da";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "kaathewise";
    repo = "nu-plugin";
    rev = version;
    sha256 = "sha256-goFxqEuc++89pQ/wsWmFUudlQoeVFFxj4WBangFdZkE=";
  };
  cargoHash = "sha256-gfZ7JdSNWFE706EfhQ9DhyJ0w3HgY/LruuDgm6xH/ss=";

  cargoBuildHook = ''
    export buildAndTestSubdir="./endecode"
  '';
  cargoCheckHook = cargoBuildHook;

  meta = with lib; {
    description = "A plugin with various encoding schemes, from Crockford's base-32 to HTML entity escaping.";
    mainProgram = "nu_plugin_endecode";
    homepage = "https://codeberg.org/kaathewise/nu-plugin/src/commit/${version}";
    license = licenses.mpl20;
    platforms = with platforms; all;
  };
}
