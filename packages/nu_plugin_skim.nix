{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_skim";
  version = "253cc7c7060f9c72cde4175f1c3d575819d40833";

  src = fetchFromGitHub {
    owner = "idanarye";
    repo = pname;
    rev = version;
    sha256 = "sha256-CwBswDVhHqPY4y7fnfL1mpTBMgu6FU8noeVwY+5I/T0=";
  };
  cargoHash = "sha256-cFni5Pp6QFEKQx/1gRsWN5AytdgilZf4PTRVO54M+OE=";

  meta = with lib; {
    description = "A nushell plugin that adds integrates the skim fuzzy finder.";
    mainProgram = "nu_plugin_skim";
    homepage = "https://github.com/idanarye/nu_plugin_skim/tree/${version}";
    license = licenses.mit;
    platforms = with platforms; all;
  };
}
