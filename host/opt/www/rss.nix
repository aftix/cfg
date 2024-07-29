{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: let
  inherit (lib) mkIf mkOverride mkForce;
  inherit (lib.attrsets) filterAttrs;
  inherit (lib.options) mkOption;
  inherit (lib.strings) concatMapStrings concatLines;
  inherit (config.services.freshrss) enable;
  cfg = config.my.www;
in {
  options.my.www.rssSubdomain = mkOption {
    default = "rss";
    type = lib.types.str;
  };

  config = mkIf enable {
    sops.secrets."freshrss_password" = {
      inherit (config.my.www) group;
      owner = config.my.www.user;
    };

    security.acme.certs.${cfg.hostname}.extraDomainNames = [
      "${cfg.rssSubdomain}.${cfg.hostname}"
      "www.${cfg.rssSubdomain}.${cfg.hostname}"
    ];

    systemd.services = {
      freshrss-config.serviceConfig = {
        User = mkForce cfg.user;
        Group = mkForce cfg.group;
        WorkingDirectory = config.services.freshrss.package;

        PrivateNetwork = true;
        UMask = mkForce "0027";
      };

      phpfpm-freshrss.serviceConfig = filterAttrs (n: v: !builtins.elem n ["IPAddressAllow" "IPAddressDeny"]) (config.my.hardenPHPFPM {
        workdir = config.services.freshrss.package;
        datadir = config.services.freshrss.dataDir;
      });
    };

    services = {
      phpfpm.pools.${config.services.freshrss.pool} = {
        user = mkForce cfg.user;
        group = mkForce cfg.group;
        settings = {
          "listen.owner" = mkForce cfg.user;
          "listen.group" = mkForce cfg.group;
        };
      };

      freshrss = {
        inherit (cfg) user;

        # Need to add extensions to the nix store path
        package = pkgs.freshrss.overrideAttrs {
          postInstall = let
            extsWithSubdirs =
              concatMapStrings (
                x: "cp -Lr \"${x}/xExtension-\"* \"$out/extensions/.\"\n"
              ) [
                inputs.freshrss-ext
                inputs.freshrss-cntools
                inputs.freshrss-links
                inputs.freshrss-ezpriorities
                inputs.freshrss-ezread
              ];
            extsAlone = concatLines (builtins.map ({
              path,
              name,
            }: "cp -Lr \"${path}\" \"$out/extensions/xExtension-${name}\"") [
              {
                path = inputs.freshrss-latex;
                name = "LatexSupport";
              }
              {
                path = inputs.freshrss-reddit;
                name = "RedditImage";
              }
              {
                path = inputs.freshrss-ttl;
                name = "AutoTTL";
              }
              {
                path = inputs.freshrss-threepane;
                name = "ThreePanesView";
              }
            ]);
          in ''
            ${extsWithSubdirs}
            ${extsAlone}
          '';
        };

        defaultUser = mkOverride 990 "aftix";
        passwordFile = mkOverride 990 config.sops.secrets."freshrss_password".path;
        baseUrl = mkOverride 990 "https://${cfg.rssSubdomain}.${cfg.hostname}";
        virtualHost = "${cfg.rssSubdomain}.${cfg.hostname}";
        database = {
          user = mkOverride 990 null;
          host = mkOverride 990 null;
        };
      };

      nginx.virtualHosts."${cfg.rssSubdomain}.${cfg.hostname}" = {
        serverName = "${cfg.rssSubdomain}.${cfg.hostname} www.${cfg.rssSubdomain}.${cfg.hostname}";
        kTLS = true;
        forceSSL = true;
        useACMEHost = cfg.hostname;
        extraConfig = ''
          include /etc/nginx/bots.d/blockbots.conf;
          include /etc/nginx/bots.d/ddos.conf;
        '';
      };
    };
  };
}
