{
  lib,
  config,
  ...
}: let
  inherit (lib) mkForce;
in {
  imports = [
    ../hardware/fermi.nix

    ./opt/aftix.nix
    ./opt/basicbackup.nix
    ./opt/docker.nix
    ./opt/openssh.nix
    ./opt/www
  ];

  sops = {
    defaultSopsFile = ./srv_secrets.yaml;
    age.keyFile = "/state/age/keys.txt";

    secrets = {
      freshrss_password = {};
      youtube_api_key = {};
    };

    templates.youtubeapi_keys = {
      mode = "0400";
      owner = config.my.www.user;
      inherit (config.my.www) group;
      content = ''
        ${config.sops.placeholder.youtube_api_key}
      '';
    };
  };

  my = {
    flake = "/home/aftix/cfg";

    users.aftix.extraGroups = [];

    www = {
      adventofcode = true;
      aftgraphs = true;
      blog = true;
      coffeepasteLocation = "litterbox";
      searx.enable = true;
      grocy.enable = true;

      ip = "170.130.165.174";
      ipv6 = "2a0b:7140:8:1:5054:ff:fe84:ed8c";
    };

    matrix = {
      enable = true;
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

    backup = {
      bucket = "fermi-backup";
      directories = [
        "/var/lib"
        "/var/log"
        "/srv"
        "/home"
        "/state"
      ];
      excludes = [
        "/var/lib/coffeepaste/**"
      ];
    };
  };

  security.sudo.extraRules = [
    {
      groups = ["wheel"];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  services = {
    atticd.enable = true;
    bpftune.enable = true;
    openssh.settings.AllowUsers = ["aftix"];
    coffeepaste = {
      enable = true;
      url = "https://${config.my.www.hostname}/${config.my.www.coffeepasteLocation}";
    };
    freshrss.enable = true;
    barcodebuddy.enable = true;
    youtube-operational-api = {
      enable = true;
      keysFile = config.sops.templates.youtubeapi_keys.path;
      inherit (config.my.www) user group;
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
