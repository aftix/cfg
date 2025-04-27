# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
# Options that are for home-manager, but should be set on a per-host basis
pkgs: lib: {
  my = {
    development.nixdConfig = lib.mkOption {
      default = {};
      description = "Configuration for the nixd LSP";
      type = with lib.types; attrsOf anything;
    };

    swayosd = {
      enable = lib.mkEnableOption "swayosd";
      package = lib.mkPackageOption pkgs "swayosd" {
        default = ["swayosd"];
      };
    };
  };
}
