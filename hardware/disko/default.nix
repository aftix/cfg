# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{lib, ...}: let
  inherit (lib.options) mkOption;
in {
  options.aftix.disko = {
    rootDrive = {
      name = mkOption {
        type = with lib.types; uniq str;
        readOnly = true;
        description = "Name of the drive from lsblk (e.g. sda, nvme0n1)";
      };

      mountOptions = mkOption {
        default = ["relatime" "nodiratime"];
        type = with lib.types; listOf str;
      };

      xdgSubvolumeUsers = mkOption {
        default = [];
        description = "List of users to configure btrfs subvolumes for ~/.cache and ~/.local/state";
      };
    };

    massDrive = {
      name = mkOption {
        readOnly = true;
        description = "Name of the drive from lsblk (e.g. sda, nvme0n1)";
      };

      device = mkOption {
        readOnly = true;
        description = "Optional name of a mass storage drive";
        example = "/dev/sda";
      };

      mountOptions = mkOption {
        default = ["relatime" "nodiratime" "noexec" "nosuid" "nodev"];
        type = with lib.types; listOf str;
      };

      subvolumes = mkOption {
        default = [];
        description = "List of subvolumes to add on the mass storage drive under /local/";
        example = ''
          [{
            name = "media";
            mountpoint = "/home/aftix/media";
          }]
        '';
      };
    };

    swap = {
      enable = mkOption {
        default = true;
      };

      size = mkOption {
        default = "8G";
        type = with lib.types; uniq str;
      };

      encrypt = mkOption {
        default = false;
      };
    };
  };
}
