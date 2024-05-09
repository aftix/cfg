{lib, ...}: let
  inherit (lib) mkForce;
in {
  imports = [
    ../hardware/fermi.nix
    ./common

    ./opt/aftix.nix
    ./opt/clamav.nix
    ./opt/docker.nix
    ./opt/openssh.nix
  ];

  sops = {
    defaultSopsFile = ./srv_secrets.yaml;
    age.keyFile = "/state/age/keys.txt";
  };

  my = {
    flake = "/home/aftix/cfg";

    users.aftix.extraGroups = [];
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
    openssh.settings.AllowUsers = ["aftix"];
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

  networking = {
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
