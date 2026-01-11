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
  version = "1.5.5";

  src = fetchFromGitHub {
    owner = "carapace-sh";
    repo = "carapace-bin";
    rev = "v${finalAttrs.version}";
    hash = "sha256-q7G7odkRwh4/w8H09exXYSC7n4CUeoG2iKb/k2D/gek=";
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
