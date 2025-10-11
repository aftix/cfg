# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  lib,
  config,
  ...
}: let
  inherit (lib) mkForce;
in {
  imports = [
    ../../hardware/fermi.nix

    ../../extraNixosModules/aftix.nix
    ../../extraNixosModules/docker.nix
    ../../extraNixosModules/hydra-substituter.nix
    ./www
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

      hydra_store_bucket = {
        mode = "0440";
        owner = "hydra";
        group = "hydra";
      };
      hydra_store_url = {
        mode = "0440";
        owner = "hydra";
        group = "hydra";
      };
      hydra_store_key_id = {
        mode = "0440";
        owner = "hydra";
        group = "hydra";
      };
      hydra_store_token = {
        mode = "0440";
        owner = "hydra";
        group = "hydra";
      };
      hydra_store_secret_key = {
        mode = "0440";
        owner = "hydra";
        group = "hydra";
      };
      hydra_store_public_key = {
        mode = "0444";
        owner = "hydra";
        group = "hydra";
      };
    };

    templates = {
      youtubeapi_keys = {
        mode = "0400";
        owner = config.aftix.www.user;
        inherit (config.aftix.www) group;
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

      hydraStore = {
        mode = "0444";
        owner = "hydra";
        group = "hydra";
        content = ''
          AWS_ACCESS_KEY_ID=${config.sops.placeholder.hydra_store_key_id}
          AWS_SECRET_ACCESS_KEY=${config.sops.placeholder.hydra_store_token}
        '';
      };
    };
  };

  aftix = let
    domain = config.aftix.statics.primaryDomain;
  in {
    ssh.enable = true;

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

      coffeepaste = {
        enable = true;
        virtualHost = domain;
        location = "litterbox";
      };

      forgejo = {
        enable = true;
        domain = "forge.${domain}";
      };

      hydra = {
        enable = false;
        domain = "hydra.${domain}";
        store_uri =
          "s3://aftix-hydra?"
          + lib.concatStringsSep "&" [
            "compression=zstd"
            "parallel-compression=true"
            "log-compreession=br"
            "ls-compression=br"
            "write-nar-listing=1"
            "secret-key=${config.sops.secrets.hydra_store_secret_key.path}"
            "scheme=https"
            "endpoint=s3.us-east-005.backblazeb2.com"
          ];
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

    users.aftix.extraGroups = lib.mkForce ["manage-units"];
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
    timerConfig = {
      OnCalendar = "03:00";
      Persistent = true;
      RandomizedDelaySec = "4h";
    };
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

      hydra = {
        description = "Hydra";
        group = "hydra";
        useDefaultShell = true;
        home = "/var/empty";
        uid = config.ids.uids.hydra;
      };
    };

    groups.docker = {};
    groups.hydra.gid = config.ids.gids.hydra;
  };

  programs.dconf.enable = true;

  systemd.services = {
    hydra-evaluator.serviceConfig = {
      MemoryHigh = "80%";
      MemoryMax = "90%";
      MemorySwapMax = "75%";
    };

    fstrim.after = ["nix-gc.service" "nix-optimise.service"];
    nix-optimise.after = ["nix-gc.service"];
  };

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
