{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkDefault mkOverride;
  inherit (lib.lists) optional;
  inherit (config.my.lib.preservation) mkDirs;
in {
  environment.systemPackages = let inherit (config.users.users.root) shell; in optional (!builtins.isString shell) shell;

  preservation.preserveAt."${config.users.users.root.home}/.local/persist".users.root = {
    home = "/root";
    directories = mkDirs [
      ".config/sops"
    ];
  };

  systemd.tmpfiles.rules = let
    inherit (config.users.users.aftix) home;
  in
    lib.mkIf config.preservation.enable
    [
      "d ${home}/.local 0755 root root -"
      "d ${home}/.local/persist 0755 root root -"
      "d ${home}/.local/persist/root 0755 root root -"
      "d ${home}/.local/persist/root/.config 0755 root root -"
      "d ${home}/.local/persist/root/.config/sops 0755 root root -"
    ];

  users.users.root = {
    shell = mkOverride 900 pkgs.zsh;
    hashedPasswordFile = mkDefault "/state/passwd.root";
  };
}
