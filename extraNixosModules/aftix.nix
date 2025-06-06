# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib) mkIf mkDefault mkOverride;
  inherit (lib.lists) optionals;
  myCfg = config.aftix.users.aftix;
  cfg = config.users.users.aftix;
in {
  options.aftix.users.aftix = {
    extraGroups = mkOption {
      default = [
        "input"
        "scanner"
        "libvirtd"
        "lp"
        "dialout"
        "lock-sessions"
      ];
      type = with lib.types; listOf str;
    };

    uid = mkOption {default = 1000;};
    mkSubUidRanges = mkOption {default = false;};
    mkSubGidRanges = mkOption {default = false;};
  };

  config = {
    aftix.users.aftix.enable = true;

    environment.systemPackages = [cfg.shell];

    security.polkit.adminIdentities = ["unix-user:aftix"];

    preservation.preserveAt."${config.users.users.aftix.home}/.local/persist".users.aftix = {
      commonMountOptions = ["x-gvfs-hide"];
      directories = [
        ".config/attic"
        ".config/ario"
        ".config/Element"
        ".config/discord"
        ".config/BetterDiscord"
        ".config/keepassxc"
        ".config/sops"
        ".config/transmission/torrents"
        ".config/transmission/blocklists"
        ".config/transmission/resume"
        ".config/Yubico"
      ];
      files = [
        ".config/nushell/history.sqlite3"
        ".config/nushell/history.sqlite3-shm"
        ".config/nushell/history.sqlite3-wal"
        ".config/transmission/dht.dat"
        ".config/transmission/stats.json"
        ".config/transmission/bandwidth-groups.json"
      ];
    };

    systemd.tmpfiles = lib.mkIf config.preservation.enable {
      rules = let
        inherit (config.users.users.aftix) home group;
      in [
        "d ${home}/.local 0755 aftix ${group} -"
        "d ${home}/.local/persist 0755 aftix ${group} -"
        "d ${home}/.local/persist/home 0755 aftix ${group} -"
        "d ${home}/.local/persist/home/aftix 0755 aftix ${group} -"
        "d ${home}/.local/persist/home/aftix/.config 0755 aftix ${group} -"
        "d ${home}/.local/persist/home/aftix/.config 0755 aftix ${group} -"
        "d ${home}/.local/persist/home/aftix/.config/attic 0755 aftix ${group} -"
        "d ${home}/.local/persist/home/aftix/.config/ario 0755 aftix ${group} -"
        "d ${home}/.local/persist/home/aftix/.config/Element 0755 aftix ${group} -"
        "d ${home}/.local/persist/home/aftix/.config/discord 0755 aftix ${group} -"
        "d ${home}/.local/persist/home/aftix/.config/BetterDiscord 0755 aftix ${group} -"
        "d ${home}/.local/persist/home/aftix/.config/keepassxc 0755 aftix ${group} -"
        "d ${home}/.local/persist/home/aftix/.config/sops 0755 aftix ${group} -"
        "d ${home}/.local/persist/home/aftix/.config/nushell 0755 aftix ${group} -"
        "f ${home}/.local/persist/home/aftix/.config/nushell/history.sqlite3 0644 aftix ${group} -"
        "f ${home}/.local/persist/home/aftix/.config/nushell/history.sqlite3-shm 0644 aftix ${group} -"
        "f ${home}/.local/persist/home/aftix/.config/nushell/history.sqlite3-wal 0644 aftix ${group} -"
        "d ${home}/.local/persist/home/aftix/.config/transmission 0755 aftix ${group} -"
        "d ${home}/.local/persist/home/aftix/.config/transmission/torrents 0755 aftix ${group} -"
        "d ${home}/.local/persist/home/aftix/.config/transmission/blocklists 0755 aftix ${group} -"
        "d ${home}/.local/persist/home/aftix/.config/transmission/resume 0755 aftix ${group} -"
        "f ${home}/.local/persist/home/aftix/.config/transmission/dht.dat 0600 aftix ${group} -"
        "f ${home}/.local/persist/home/aftix/.config/transmission/stats.json 0600 aftix ${group} -"
        "f ${home}/.local/persist/home/aftix/.config/transmission/bandwidth-groups.json 0600 aftix ${group} -"
        "d ${home}/.local/persist/home/aftix/.config/Yubico 0755 aftix ${group} -"
      ];
      settings.preservation = let
        inherit (config.users.users.aftix) home group;
      in {
        "${home}/.config/nushell".d = {
          user = "aftix";
          inherit group;
        };
        "${home}/.config/transmission".d = {
          user = "aftix";
          inherit group;
        };
      };
    };

    users.users.aftix = {
      uid = mkDefault 1000;
      hashedPasswordFile = mkDefault "/state/passwd.aftix";
      shell = mkOverride 900 pkgs.zsh;
      isNormalUser = true;

      extraGroups =
        [
          "wheel"
          "power-management"
          "idle-inhibit"
        ]
        ++ optionals myCfg.enable
        myCfg.extraGroups;

      subUidRanges = mkIf myCfg.mkSubUidRanges [
        {
          count = 65536;
          startUid = 231072;
        }
      ];

      subGidRanges = mkIf myCfg.mkSubGidRanges [
        {
          count = 65536;
          startGid = 231072;
        }
      ];
    };
  };
}
