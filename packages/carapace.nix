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
  version = "1.4.1-unstable-2025-08-28";

  src = fetchFromGitHub {
    owner = "carapace-sh";
    repo = "carapace-bin";
    rev = "740191189694d5a997117df4e67c89471af1dd4c";
    hash = "sha256-aI69LQuyXUGqxjcUIH3J8AG7cgn/onBg0mZc+zz+YrA=";
  };

  vendorHash = "sha256-AwR+Oh1Rlg1z/pYdc9VDvp/FLH1ZiPsP/q4lks3VqqE=";

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

  passthru.updateScript = nix-update-script {};
  passthru.tests.version = testers.testVersion {package = carapace;};

  meta = {
    description = "Multi-shell multi-command argument completer";
    homepage = "https://carapace.sh/";
    license = lib.licenses.mit;
    mainProgram = "carapace";
    updateVersion = "branch";
  };
})
