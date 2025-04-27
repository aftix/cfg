# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  lib,
  config,
  ...
}: let
  inherit (lib.attrsets) optionalAttrs mergeAttrsList;
  inherit (lib.options) mkOption;
  inherit (lib.lists) optional;

  inherit (config.dep-inject) inputs;
  cfg = config.aftix.channels;
in {
  options.aftix.channels = {
    enable = mkOption {default = true;};

    basePath = mkOption {
      default = "/etc/nixpkgs/channels";
      description = "base path where all channels will be created";
    };

    nixpkgs = {
      enable = mkOption {default = true;};
      path = mkOption {
        default = "nixpkgs";
        description = "path relative to aftix.channels.basePath where this channel will be available";
      };
      relativePath = mkOption {
        default = true;
        description = "treat channel path as relative to aftix.channels.basePath";
      };
    };

    home-manager = {
      enable = mkOption {default = true;};
      path = mkOption {
        default = "home-manager";
        description = "path relative to aftix.channels.basePath where this channel will be available";
      };
      relativePath = mkOption {
        default = true;
        description = "treat channel path as relative to aftix.channels.basePath";
      };
    };
  };

  config = let
    toDir = attrs:
      if attrs.relativePath
      then "${cfg.basePath}/${attrs.path}"
      else attrs.path;

    toNixPath = name: attrs:
      optional attrs.enable
      "${name}=${toDir attrs}";

    toTmpfilesSetting = mod: attrs:
      optionalAttrs attrs.enable {
        ${toDir attrs}."L+".argument = builtins.toString mod;
      };
  in
    lib.mkIf cfg.enable {
      nix.nixPath =
        (toNixPath "nixpkgs" cfg.nixpkgs)
        ++ (toNixPath "home-manager" cfg.home-manager);

      systemd.tmpfiles.settings."10-nix-channels" = mergeAttrsList [
        (toTmpfilesSetting inputs.nixpkgs cfg.nixpkgs)
        (toTmpfilesSetting inputs.home-manager cfg.home-manager)
      ];
    };
}
