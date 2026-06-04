# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{lib, ...}: {
  systemd.network.enable = lib.mkDefault true;

  networking.firewall = {
    enable = lib.mkDefault true;
    checkReversePath = lib.mkDefault false;
  };

  services.resolved = {
    enable = lib.mkDefault true;
    settings.Resolve = {
      FallbackDNS = lib.mkDefault [
        "1.1.1.1"
        "1.0.0.1"
        "2606:4700:4700::1111"
        "2606:4700:4700::1001"
      ];
      Domains = lib.mkDefault ["~."];
      DNSOverTLS = lib.mkDefault "true";
    };
  };
}
