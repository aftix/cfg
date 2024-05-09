{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkDefault mkOverride;
  inherit (lib.lists) optional;
in {
  environment.systemPackages = let inherit (config.users.users.root) shell; in optional (!builtins.isString shell) shell;
  users.users.root = {
    shell = mkOverride 900 pkgs.zsh;
    hashedPasswordFile = mkDefault "/state/passwd.root";
  };
}
