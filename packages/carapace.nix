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
  version = "1.6.0";

  src = fetchFromGitHub {
    owner = "carapace-sh";
    repo = "carapace-bin";
    rev = "v${finalAttrs.version}";
    hash = "sha256-btExAFj3nnq5vv3LJgUA7pdmQhd6ANUexC/AQcIg0Ms=";
  };

  vendorHash = "sha256-7Gmt4ZHmYK5IukQYuY0felhW+ul23wSDX9PJyI6rDWQ=";
  proxyVendor = true;

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
