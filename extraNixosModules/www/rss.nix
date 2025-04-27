# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf mkOverride mkForce;
  inherit (lib.attrsets) filterAttrs;
  inherit (lib.options) mkEnableOption mkOption;

  wwwCfg = config.aftix.www;
  cfg = config.aftix.www.rss;

  acmeHost =
    if cfg.acmeDomain == null
    then cfg.domain
    else cfg.acmeDomain;
in {
  options.aftix.www.rss = {
    enable = mkEnableOption "rss";

    domain = mkOption {
      type = lib.types.str;
    };

    acmeDomain = mkOption {
      default = wwwCfg.acmeDomain;
      type = with lib.types; nullOr str;
      description = "null to use \${aftix.www.rss.domain}";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets."freshrss_password" = {
      owner = "freshrss";
      group = "freshrss";
    };

    security.acme.certs =
      if (acmeHost != cfg.domain)
      then {
        ${acmeHost}.extraDomainNames = [
          "${cfg.domain}"
          "www.${cfg.domain}"
        ];
      }
      else {
        ${acmeHost} = {
          inherit (wwwCfg) group;
          extraDomainNames = ["www.${cfg.domain}"];
        };
      };

    systemd = {
      services = {
        freshrss-config.serviceConfig = {
          User = mkForce "freshrss";
          Group = mkForce "freshrss";
          WorkingDirectory = config.services.freshrss.package;
          StateDirectory = "freshrss";
          ReadWritePaths = mkForce ["/run/phpfpm"];

          PrivateNetwork = true;
          UMask = mkForce "0027";
        };

        phpfpm-freshrss.serviceConfig = filterAttrs (n: v: !builtins.elem n ["IPAddressAllow" "IPAddressDeny"]) (config.aftix.hardenPHPFPM {
          workdir = config.services.freshrss.package;
          datadir = "/var/lib/freshrss";
        });
      };

      tmpfiles.settings."10-freshrss"."/var/lib/freshrss" = rec {
        d = {
          mode = "0750";
          user = "freshrss";
          group = "freshrss";
        };
        Z = d;
      };
    };

    services = {
      phpfpm.pools.${config.services.freshrss.pool} = {
        user = mkForce "freshrss";
        group = mkForce "freshrss";
        settings = {
          "listen.owner" = mkForce "freshrss";
          "listen.group" = mkForce "freshrss";
          "listen.mode" = mkForce "0666";
        };
      };

      freshrss = {
        enable = true;

        user = "freshrss";

        extensions = with pkgs.freshrssExts; [
          official
          cntools
          latex
          reddit
          autottl
          links
          ezpriorities
          ezread
          threepane
        ];

        defaultUser = mkOverride 990 "aftix";
        passwordFile = mkOverride 990 config.sops.secrets."freshrss_password".path;
        baseUrl = mkOverride 990 "https://${cfg.domain}";
        virtualHost = cfg.domain;
        database = {
          user = mkOverride 990 null;
          host = mkOverride 990 null;
        };
      };

      nginx = {
        enable = true;

        virtualHosts.${cfg.domain} = {
          serverName = "${cfg.domain} www.${cfg.domain}";
          kTLS = true;
          forceSSL = true;
          useACMEHost = acmeHost;
          extraConfig = ''
            include /etc/nginx/bots.d/blockbots.conf;
            include /etc/nginx/bots.d/ddos.conf;
          '';
        };
      };

      youtube-operational-api = {
        enable = true;
        keysFile = config.sops.templates.youtubeapi_keys.path;
      };
    };

    users = {
      users.freshrss = {
        group = "freshrss";
        isSystemUser = true;
        shell = lib.getExe' pkgs.util-linux "nologin";
      };

      groups.freshrss = {};
    };
  };
}
