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
  version = "1.5.4-unstable-2025-11-11";

  src = fetchFromGitHub {
    owner = "carapace-sh";
    repo = "carapace-bin";
    rev = "281eb92a11110d3c6655ee8fa0ac9f7aae96ab3e";
    hash = "sha256-WQC/SzOUwW+vDEOXtknhPUZrHqsxC4n2zQCu12Ytuic=";
  };

  vendorHash = "sha256-eADiOSLqouH9saTgbbQY18wc3DxCBvqdVKI32I7sTWQ=";

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
