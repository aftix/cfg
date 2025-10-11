# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkForce;
in {
  imports = [
    ../../extraNixosModules/display.nix
  ];

  users.users.root.hashedPasswordFile = null;

  aftix.sound = true;

  boot = {
    kernelPackages = lib.mkForce pkgs.linuxPackages_6_6;
    initrd.systemd.enable = lib.mkForce false;
  };

  environment = {
    systemPackages = with pkgs; [
      btrfs-progs
    ];

    etc."nixos-custom" = {
      mode = "0755";
      source = ../..;
    };
  };

  systemd.oomd = {
    enableRootSlice = true;
    enableSystemSlice = true;
    enableUserSlices = true;
  };

  services = {
    udisks2.enable = true;

    greetd.settings = {
      initial_session.user = mkForce "nixos";
      default_session.user = mkForce "nixos";
    };
  };

  networking.hostName = "custom-install-iso";
}
