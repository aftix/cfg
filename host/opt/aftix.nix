{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib) mkIf mkDefault mkOverride;
  myCfg = config.my.users.aftix;
  cfg = config.users.users.aftix;
in {
  options.my.users.aftix = {
    hashedPasswordFile = mkOption {default = "/state/passwd.aftix";};
    extraGroups = mkOption {
      default = [
        "networkmanager"
        "scanner"
        "lp"
        "dialout"
      ];
    };

    uid = mkOption {default = 1000;};
    mkSubUidRanges = mkOption {default = false;};
    mkSubGidRanges = mkOption {default = false;};
  };

  config = {
    my.users.aftix.enable = true;

    environment.systemPackages = [cfg.shell];

    users.users.aftix = {
      uid = mkDefault 1000;
      hashedPasswordFile = mkDefault "/state/passwd.aftix";
      shell = mkOverride 900 pkgs.zsh;
      isNormalUser = true;

      extraGroups =
        [
          "wheel"
        ]
        ++ (
          if myCfg.enable
          then myCfg.extraGroups
          else []
        );

      subUidRanges = mkIf myCfg.mkSubUidRanges [
        {
          count = 65536;
          startUid = 231072;
        }
      ];

      subGidRanges = mkIf myCfg.mkSubGidRanges [
        {
          count = 65536;
          startGid = 231072;
        }
      ];
    };
  };
}