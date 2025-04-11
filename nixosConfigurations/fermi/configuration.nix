{
  lib,
  config,
  ...
}: let
  inherit (lib) mkForce;
in {
  imports = [
    ../../hardware/fermi.nix

    ../../host/opt/aftix.nix
    ../../host/opt/docker.nix
    ../../host/opt/openssh.nix
    ../../host/opt/pull-updates.nix
    ../../host/opt/www
  ];

  sops = {
    defaultSopsFile = ../../secrets/host/srv_secrets.yaml;
    age.keyFile = "/state/age/keys.txt";

    secrets = {
      freshrss_password = {};
      youtube_api_key = {};
      restic_fermi_password = {};
      restic_fermi_aws_id = {};
      restic_fermi_aws_secret = {};
    };

    templates = {
      youtubeapi_keys = {
        mode = "0400";
        owner = config.my.www.user;
        inherit (config.my.www) group;
        content = ''
          ${config.sops.placeholder.youtube_api_key}
        '';
      };

      restic = {
        mode = "0400";
        content = ''
          AWS_ACCESS_KEY_ID=${config.sops.placeholder.restic_fermi_aws_id}
          AWS_SECRET_ACCESS_KEY=${config.sops.placeholder.restic_fermi_aws_secret}
        '';
      };
    };
  };

  aftix.pull-updates.enable = true;

  my = let
    domain = config.aftix.statics.primaryDomain;
  in {
    users.aftix.extraGroups = lib.mkForce ["manage-units"];

    attic = {
      enable = true;
      domain = "attic.${domain}";
    };

    www = let
      node = (import ../../nodes.nix).fermi;
    in {
      blog = {
        enable = true;
        inherit domain;
      };

      barcodebuddy = {
        enable = true;
        domain = "bbuddy.${domain}";
      };

      coffeepaste = {
        enable = true;
        virtualHost = domain;
        location = "litterbox";
      };

      forgejo = {
        enable = true;
        domain = "forge.${domain}";
      };

      grocy = {
        enable = true;
        domain = "grocy.${domain}";
      };

      hydra = {
        enable = true;
        domain = "hydra.${domain}";
      };

      kanidm.enable = true;

      rss = {
        enable = true;
        domain = "rss.${domain}";
      };

      searx = {
        enable = true;
        domain = "searx.${domain}";
      };

      acmeDomain = domain;
      inherit (node) ip ipv6;
    };

    matrix = {
      enable = true;
      virtualHost = domain;

      supportEndpointJSON.contacts = [
        {
          email_address = "aftix@aftix.xyz";
          matrix_id = "@aftix:matrix.org";
          role = "m.role.admin";
        }
      ];

      ircBridge = {
        enable = true;
        identd.enable = true;
      };
    };
  };

  services = {
    bpftune.enable = true;
    openssh.settings.AllowUsers = ["aftix"];
  };

  services.restic.backups.backblaze = {
    paths = [
      "/var/lib"
      "/var/log"
      "/srv"
      "/home"
      "/state"
    ];
    exclude = ["/var/lib/coffeepaste/**"];
    environmentFile = config.sops.templates.restic.path;
    passwordFile = config.sops.secrets.restic_fermi_password.path;
    repository = "s3:s3.us-east-005.backblazeb2.com/aftix-fermi-restic";
    inhibitsSleep = true;
    initialize = true;
    pruneOpts = ["--keep-last 156"];
    checkOpts = ["--with-cache"];
  };

  users = {
    users = {
      root = {
        hashedPasswordFile = mkForce null;
        password = mkForce "";
        shell = "/run/current-system/sw/bin/nologin";
      };

      docker = {
        password = "";
        shell = "/run/current-system/sw/bin/nologin";
        isSystemUser = true;
        group = "docker";

        subUidRanges = [
          {
            count = 65536;
            startUid = 231072;
          }
        ];
        subGidRanges = [
          {
            count = 65536;
            startGid = 231072;
          }
        ];
      };
    };

    groups.docker = {};
  };

  programs.dconf.enable = true;

  networking = {
    hostName = "fermi";

    dhcpcd = {
      IPv6rs = true;
      persistent = true;
    };

    tempAddresses = "disabled";
    interfaces.ens3.tempAddress = "disabled";

    firewall = {
      enable = true;
      checkReversePath = false;
    };
  };

  time.timeZone = "America/Chicago";

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.05"; # Did you read the comment?
}
