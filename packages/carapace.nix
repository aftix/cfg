# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (c) 2003-2025 Eelco Dolstra and the Nixpkgs/NixOS contributors
# SPDX-License-Identifier: MIT
# SPDX-FileComment: Taken from https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/shells/carapace/default.nix
# SPDX-FileComment: Modified slightly to fit in with this repo's conventions
{
  lib,
  buildGoModule,
  fetchFromGitHub,
  testers,
  carapace,
  nix-update-script,
}:
buildGoModule (finalAttrs: {
  pname = "carapace";
  version = "1.5.2-unstable-2025-10-07";

  src = fetchFromGitHub {
    owner = "carapace-sh";
    repo = "carapace-bin";
    rev = "6f4b786d962ff36d93b8da88ce8dbe4dc1094c62";
    hash = "sha256-nkyAajnrJNx9uggDQ9xrDR6MrpsLyqO/kYbF0o841D0=";
  };

  vendorHash = "sha256-mE22eTfajasKgxhhGWDyDTCk6F863a1HXLX1vh86f48=";

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${finalAttrs.version}"
  ];

  subPackages = ["./cmd/carapace"];

  tags = ["release"];

  preBuild = ''
    GOOS= GOARCH= go generate ./...
  '';

  passthru = {
    tests.version = testers.testVersion {package = carapace;};
    updateScript = nix-update-script {
      extraArgs = ["--version" "branch"];
    };
  };

  meta = {
    description = "Multi-shell multi-command argument completer";
    homepage = "https://carapace.sh/";
    license = lib.licenses.mit;
    mainProgram = "carapace";
  };
})
