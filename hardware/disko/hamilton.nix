# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  config,
  lib,
  ...
}: let
  inherit (lib.attrsets) mergeAttrsList;
  inherit (lib) mkIf mkMerge;
  cfg = config.my.disko;
in {
  imports = [./default.nix];

  disko.devices = {
    disk = mkMerge [
      {
        ${cfg.rootDrive.name} = {
          type = "disk";
          name = "nixos";
          device = "/dev/${cfg.rootDrive.name}";

          content = {
            type = "gpt";

            partitions = {
              boot = {
                name = "boot";
                label = "ESP";

                type = "EF00";
                priority = 1;
                start = "2048";
                end = "999423";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [
                    "noexec"
                    "nodev"
                    "nosuid"
                    "relatime"
                    "nodiratime"
                  ];
                };
              };

              root = {
                name = "root";
                label = "root";

                end = mkIf cfg.swap.enable "$-{cfg.swap.size}";
                size = mkIf (!cfg.swap.enable) "100%";

                content = {
                  type = "btrfs";
                  extraArgs = ["-f"]; # override existing

                  subvolumes = mergeAttrsList ((builtins.map (username: let
                        home = "/home/" + username;
                      in {
                        "local/${username}/state" = {
                          mountpoint = "${home}/.local/state";
                          mountOptions =
                            [
                              "nodev"
                              "nosuid"
                            ]
                            ++ (builtins.filter (opt: opt != "noexec") cfg.rootDrive.mountOptions);
                        };
                        "local/${username}/cache" = {
                          mountpoint = "${home}/.cache";
                          mountOptions =
                            [
                              "nodev"
                              "nosuid"
                              "noexec"
                            ]
                            ++ cfg.rootDrive.mountOptions;
                        };
                      })
                      cfg.rootDrive.xdgSubvolumeUsers)
                    ++ [
                      {
                        "local/root@blank" = {};
                        "local/root" = {
                          mountpoint = "/";
                          inherit (cfg.rootDrive) mountOptions;
                        };
                        "local/nix" = {
                          mountpoint = "/nix";
                          mountOptions = builtins.filter (opt: opt != "noexec") cfg.rootDrive.mountOptions;
                        };
                        "local/state" = {
                          mountpoint = "/state";
                          inherit (cfg.rootDrive) mountOptions;
                        };
                        "safe/persist" = {
                          mountpoint = "/persist";
                          inherit (cfg.rootDrive) mountOptions;
                        };
                        "safe/home" = {
                          mountpoint = "/home";
                          mountOptions = ["nodev" "nosuid"] ++ cfg.rootDrive.mountOptions;
                        };
                      }
                    ]);
                };
              };

              swap = mkIf cfg.swap.enable {
                name = "swap";
                label = "swap";

                size = "100%";
                content = {
                  type = "swap";
                  randomEncryption = cfg.swap.encrypt;
                  resumeDevice = true;
                };
              };
            };
          };
        };
      }

      (mkIf (builtins.hasAttr "device" cfg.massDrive)
        {
          ${cfg.massDrive.name} = {
            type = "disk";
            name = "mass";
            device = "/dev/${cfg.massDrive.name}";
            content = {
              type = "gpt";
              partitions.mass = {
                name = "mass";
                label = "mass";
                size = "100%";

                content = {
                  inherit (cfg.massDrive) mountOptions;
                  type = "btrfs";
                  subvolumes = mergeAttrsList (builtins.map ({
                      name,
                      mountpoint ? "",
                    }: {
                      "local/${name}" = {
                        inherit mountpoint;
                        mountOptions = ["x-systemd.automount" "nofail"] ++ cfg.massDrive.mountOptions;
                      };
                    })
                    cfg.massDrive.subvolumes);
                };
              };
            };
          };
        })
    ];

    nodev = mergeAttrsList (builtins.map (username: let
        home = "/home/" + username;
        inherit (config.users.users.${username}) uid group;
        inherit (config.users.groups.${group}) gid;
      in {
        "${home}/.config" = {
          fsType = "tmpfs";
          mountOptions = [
            "size=2G"
            "nosuid"
            "noexec"
            "nodev"
            "mode=0750"
            "uid=${builtins.toString uid}"
            "gid=${builtins.toString gid}"
          ];
        };

        "${home}/Downloads" = {
          fsType = "tmpfs";
          mountOptions = [
            "size=2G"
            "nosuid"
            "noexec"
            "nodev"
            "mode=0750"
            "uid=${builtins.toString uid}"
            "gid=${builtins.toString gid}"
          ];
        };
      })
      cfg.rootDrive.xdgSubvolumeUsers);
  };
}
