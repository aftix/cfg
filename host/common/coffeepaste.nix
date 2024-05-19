{
  config,
  lib,
  pkgs,
  inputs,
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
    nixpkgs.overlays = [
      (final: _: {
        coffeepaste = final.rustPlatform.buildRustPackage rec {
          pname = "coffeepaste";
          version = "1.5.1";

          src = inputs.coffeepaste;
          cargoLock.lockFile = "${src}/Cargo.lock";

          nativeBuildInputs = with pkgs; [
            pkg-config
          ];
          buildInputs = with pkgs; [
            glib
            gexiv2
          ];

          postInstall = ''
            mkdir -p "$out/share"
            cp ${configFile} "$out/share/config.toml"
          '';

          meta = with pkgs.lib; {
            description = "A neat pastebin";
            homepage = "https://git.sr.ht/~mort/coffeepaste";
            license = licenses.agpl3Only;
            maintainers = [
              {
                name = "aftix";
                email = "aftix@aftix.xyz";
                github = "aftix";
              }
            ];
          };
        };
      })
    ];

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
          WorkingDirectory = "${pkgs.coffeepaste}/share";
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
