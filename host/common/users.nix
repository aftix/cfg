{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib.options) mkOption mkPackageOption;
  inherit (lib) mkIf;
  cfg = config.my.users;
in {
  options.my.users = {
    aftix = {
      enable = mkOption {default = true;};
      hashedPasswordFile = mkOption {default = "/state/passwd.aftix";};
      extraGroups = mkOption {
        default = [
          "networkmanager"
          "scanner"
          "lp"
          "dialout"
        ];
      };

      shell =
        mkPackageOption pkgs "zsh" {
        };

      uid = mkOption {default = 1000;};
      mkSubUidRanges = mkOption {default = false;};
      mkSubGidRanges = mkOption {default = false;};
    };

    root = {
      hashedPasswordFile = mkOption {default = "/state/passwd.aftix";};
      shell =
        mkPackageOption pkgs "zsh" {
        };
    };
  };

  config = {
    environment.systemPackages = [
      cfg.aftix.shell
      cfg.root.shell
    ];

    security.sudo = {
      enable = true;
      execWheelOnly = true;
      extraConfig = "Defaults lecture = never";
    };

    users = {
      mutableUsers = false;

      users = {
        aftix = mkIf cfg.aftix.enable {
          inherit (cfg.aftix) uid shell hashedPasswordFile;
          isNormalUser = true;

          extraGroups =
            [
              "wheel"
            ]
            ++ cfg.aftix.extraGroups;

          subUidRanges = mkIf cfg.aftix.mkSubUidRanges [
            {
              count = 65536;
              startUid = 231072;
            }
          ];
          subGidRanges = mkIf cfg.aftix.mkSubGidRanges [
            {
              count = 65536;
              startGid = 231072;
            }
          ];
        };

        root = {inherit (cfg.root) shell hashedPasswordFile;};
      };
    };
  };
}
