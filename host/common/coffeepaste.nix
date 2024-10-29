{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault;
  inherit (lib.options) mkOption mkEnableOption;

  cfg = config.services.coffeepaste;

  configFile = (pkgs.formats.toml {}).generate "config.toml" {
    inherit (cfg) url max_file_size expiration_days;
    listen = "${cfg.listenAddr}:${builtins.toString cfg.listenPort}";
    data = "${cfg.dataDir}";
  };
  configDrv = pkgs.runCommandLocal "coffeepaste-config" {} ''
    mkdir -p $out
    cp -vL "${configFile}" $out/config.toml
  '';
in {
  options.services.coffeepaste = {
    enable = mkEnableOption "coffeepaste";

    user = mkOption {
      default = "coffeepaste";
      type = lib.types.str;
    };

    group = mkOption {
      default = "coffeepaste";
      type = lib.types.str;
    };

    url = mkOption {
      default = "https://example.com";
      type = lib.types.str;
    };

    listenAddr = mkOption {
      default = "[::1]";
      type = lib.types.str;
    };
    listenPort = mkOption {
      default = 8080;
      type = lib.types.ints.unsigned;
    };

    dataDir = mkOption {
      default = "/var/lib/coffeepaste";
      type = lib.types.path;
    };

    max_file_size = mkOption {
      default = 15000000;
      type = lib.types.ints.unsigned;
    };

    expiration_days = mkOption {
      default = 30;
      type = lib.types.ints.unsigned;
    };
  };

  config = lib.mkIf cfg.enable {
    users = {
      users.${cfg.user} = {
        isSystemUser = mkDefault true;
        group = mkDefault cfg.group;
        shell = mkDefault "/run/current-system/sw/bin/nologin";
      };
      groups.${cfg.group} = {};
    };

    systemd = {
      tmpfiles.rules = [
        "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group} -"
      ];

      services.coffeepaste = {
        wants = ["network.target"];
        after = ["network.target"];
        wantedBy = ["multi-user.target"];
        unitConfig.Description = "A neat pastebin";

        serviceConfig = {
          User = cfg.user;
          Group = cfg.group;
          WorkingDirectory = "${configDrv}";
          ReadWritePaths = cfg.dataDir;

          CapabilityBoundingSet = config.my.systemdCapabilities;
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          NoNewPrivileges = true;
          PrivateDevices = true;
          PrivateTmp = true;
          PrivateUsers = true;
          ProtectHome = true;
          ProtectHostname = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectProc = "invisible";
          ProtectSystem = "strict";
          RemoveIPC = true;
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          SystemCallArchitectures = "native";
          UMask = "0027";
        };
        script = "${pkgs.coffeepaste}/bin/coffeepaste";
      };
    };
  };
}
