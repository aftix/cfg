{
  lib,
  config,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib.lists) optional;

  inherit (config.dep-inject) inputs;
  cfg = config.my.channels;
in {
  options.my.channels = {
    enable = mkOption {default = true;};

    basePath = mkOption {
      default = "/etc/nixpkgs/channels";
      description = "base path where all channels will be created";
    };

    nixpkgs = {
      enable = mkOption {default = true;};
      path = mkOption {
        default = "nixpkgs";
        description = "path relative to my.channels.basePath where this channel will be available";
      };
      relativePath = mkOption {
        default = true;
        description = "treat channel path as relative to my.channels.basePath";
      };
    };

    stablepkgs = {
      enable = mkOption {default = true;};
      path = mkOption {
        default = "nixpkgs-23.11";
        description = "path relative to my.channels.basePath where this channel will be available";
      };
      relativePath = mkOption {
        default = true;
        description = "treat channel path as relative to my.channels.basePath";
      };
    };

    home-manager = {
      enable = mkOption {default = true;};
      path = mkOption {
        default = "home-manager";
        description = "path relative to my.channels.basePath where this channel will be available";
      };
      relativePath = mkOption {
        default = true;
        description = "treat channel path as relative to my.channels.basePath";
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

    toTmpfilesRule = mod: attrs:
      optional attrs.enable
      "L+ ${toDir attrs} - - - - ${mod}";
  in
    lib.mkIf cfg.enable {
      nix.nixPath =
        (toNixPath "nixpkgs" cfg.nixpkgs)
        ++ (toNixPath "stablepkgs" cfg.stablepkgs)
        ++ (toNixPath "home-manager" cfg.home-manager);

      systemd.tmpfiles.rules =
        (toTmpfilesRule inputs.nixpkgs cfg.nixpkgs)
        ++ (toTmpfilesRule inputs.stablepkgs cfg.stablepkgs)
        ++ (toTmpfilesRule inputs.home-manager cfg.home-manager);
    };
}
