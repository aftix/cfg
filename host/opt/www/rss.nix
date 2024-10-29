{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf mkOverride mkForce;
  inherit (lib.attrsets) filterAttrs;
  inherit (lib.options) mkOption;

  inherit (config.services.freshrss) enable;
  cfg = config.my.www;

  inherit (pkgs) fetchFromGitHub fetchFromGitLab;

  freshrss-ext = fetchFromGitHub {
    owner = "FreshRSS";
    repo = "Extensions";
    rev = "37c66324907d6f2a5fc97d6175bfa4de01ac540c";
    hash = "sha256-mbfsXXnV4EtrIlRCZupwqLVHPlYsYJCsstmbYVatFS8=";
  };

  freshrss-cntools = fetchFromGitHub {
    owner = "cn-tools";
    repo = "cntools_FreshRssExtensions";
    rev = "4860d96e8cc46a1baba6b1b0588dc6f9d6b400e5";
    hash = "sha256-1YLAhCsEymPmNZAGKrvGM+4Bfy8WeDWQVEM3JUKsyqY=";
  };

  freshrss-latex = fetchFromGitHub {
    owner = "aledeg";
    repo = "xExtension-LatexSupport";
    rev = "c3e8a5961e47da53d112522e27586f7734b265d0";
    hash = "sha256-DvL5tyj0FHVCL9ZcBSLuZ01shB448WDVpQmgkYLhoLs=";
  };

  freshrss-reddit = fetchFromGitHub {
    owner = "aledeg";
    repo = "xExtension-RedditImage";
    rev = "b2aaf6bcf56f60c937dc157cf0f5c6b0fa41f784";
    hash = "sha256-H/uxt441ygLL0RoUdtTn9Q6Q/Ois8RHlhF8eLpTza4Q=";
  };

  freshrss-ttl = fetchFromGitHub {
    owner = "mgnsk";
    repo = "FreshRSS-AutoTTL";
    rev = "3bf43ca057f7efb57deca1ddb4f7ad0a8cf11bae";
    hash = "sha256-pLuGwwlowLWHlY5V3jiN84rCzUxn/QUTkUMMc6+C3HM=";
  };

  freshrss-links = fetchFromGitHub {
    owner = "kapdap";
    repo = "freshrss-extensions";
    rev = "a44a25a6b8c7f298ac05b8db323bdea931e6e530";
    hash = "sha256-uWZi0sHdfDENJqjqTz5yoDZp3ViZahYI2OUgajdx4MQ=";
  };

  freshrss-ezpriorities = fetchFromGitHub {
    owner = "aidistan";
    repo = "freshrss-extensions";
    rev = "ed569b32c31080d2f8f77a67fc6e3da0e7b7aebf";
    hash = "sha256-FOhVZLsdRY1LszT7YlYV70WUQUelyj1uY9d3h7eTX4w=";
  };

  freshrss-ezread = fetchFromGitHub {
    owner = "kalvn";
    repo = "freshrss-mark-previous-as-read";
    rev = "53be867476bcf174a90fcd23edac975cb251a742";
    hash = "sha256-9Ra7FVYJuMdW1+W19KbHxb91MWiJe1mICDYXr11DBe8=";
  };

  freshrss-threepane = fetchFromGitLab {
    domain = "framagit.org";
    owner = "nicofrand";
    repo = "xextension-threepanesview";
    rev = "3863ec5e3c0acdc33f0378cb8985b20dc9c810b7";
    hash = "sha256-3dva36Wgia3/qJB1tH/7trja7KFY9DVrnCQwD6/dNPs=";
  };
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

        extensions = let
          mkExtensionWithSubdirs = src:
            pkgs.runCommand "freshrss-extension" {} ''
              mkdir -p "$out/share/freshrss/extensions"
              cp -vLr "${src}/xExtension-"* "$out/share/freshrss/extensions/"
            '';
          extsWithSubdirs = builtins.map mkExtensionWithSubdirs [
            freshrss-ext
            freshrss-cntools
            freshrss-links
            freshrss-ezpriorities
            freshrss-ezread
          ];

          mkExtensionAlone = {
            path,
            name,
          }:
            pkgs.runCommand "freshrss-extension-${name}" {} ''
              mkdir -p "$out/share/freshrss/extensions"
              cp -vLr "${path}" "$out/share/freshrss/extensions/xExtension-${name}"
            '';
          extsAlone = builtins.map mkExtensionAlone [
            {
              path = freshrss-latex;
              name = "LatexSupport";
            }
            {
              path = freshrss-reddit;
              name = "RedditImage";
            }
            {
              path = freshrss-ttl;
              name = "AutoTTL";
            }
            {
              path = freshrss-threepane;
              name = "ThreePanesView";
            }
          ];
        in
          extsWithSubdirs ++ extsAlone;

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
