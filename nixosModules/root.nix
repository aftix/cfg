# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
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

  preservation.preserveAt."${config.users.users.root.home}/.local/persist".users.root = {
    home = "/root";
    commonMountOptions = ["x-gvfs-hide"];
    directories = [
      ".config/sops"
    ];
  };

  systemd.tmpfiles.settings."10-root-home-persist" = let
    inherit (config.users.users.aftix or {home = "";}) home;
  in
    lib.mkIf (config.preservation.enable && (home != "")) {
      "${home}/.local".d = {
        mode = "0755";
        user = "aftix";
        group = "users";
      };

      "${home}/.local/persist".d = {
        mode = "0755";
        user = "aftix";
        group = "users";
      };

      "${home}/.local/persist/root".d = {
        mode = "0755";
        user = "root";
        group = "root";
      };

      "${home}/.local/persist/root/.config".d = {
        mode = "0755";
        user = "root";
        group = "root";
      };

      "${home}/.local/persist/root/.config/sops".d = {
        mode = "0755";
        user = "root";
        group = "root";
      };
    };

  users.users.root = {
    shell = mkOverride 900 pkgs.zsh;
    hashedPasswordFile = mkDefault "/state/passwd.root";
  };
}
