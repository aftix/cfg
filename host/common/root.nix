{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkDefault mkOverride;
in {
  environment.systemPackages = [config.users.users.root.shell];
  users.users.root = {
    shell = mkOverride 900 pkgs.zsh;
    hashedPasswordFile = mkDefault "/state/passwd.root";
  };
}
