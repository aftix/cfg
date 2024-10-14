{
  lib,
  stdenv,
  nginxBlacklist,
}:
stdenv.mkDerivation {
  pname = "nginx-ultimate-bad-bot-blocker";
  version = "1";

  src = nginxBlacklist;

  installPhase = ''
    mkdir -p "$out"
    cp -R *.d "$out/."
  '';

  meta = with lib; {
    description = "nginx ultimate bad bot blocker";
    homepage = "https://github.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker";
    license = licenses.mit;
    platforms = with platforms; all;
  };
}