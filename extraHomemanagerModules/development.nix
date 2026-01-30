# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf mkDefault mkMerge;
  inherit (lib.lists) optional optionals;
  inherit (lib.options) mkOption;
  inherit (config.xdg) dataHome cacheHome stateHome;
  cfg = config.aftix.development;
in {
  imports = [./vcs.nix];

  options.aftix.development = {
    nix = mkOption {default = true;};
    rust = mkOption {default = true;};
    go = mkOption {default = true;};
    cpp = mkOption {default = true;};
    typescript = mkOption {default = false;};
    gh = mkOption {default = true;};
    steel = mkOption {default = true;};
  };

  config = {
    home = {
      activation = mkIf cfg.steel {
        makeSteelLSPDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
          run mkdir ''${VERBOSE_ARG} -p "${config.xdg.stateHome}/steel-language-server"
        '';
      };

      packages = with pkgs;
        [
          shellcheck
          gnupatch
          gnumake
          gawk
          just
          tokei
        ]
        ++ optionals cfg.nix
        [
          statix
          alejandra
          nix-output-monitor
          npins
          nvd
          nurl
        ]
        ++ optionals cfg.rust
        [
          rusty-man
          rustup
          bacon
          cargo-info
          cargo-nextest
          cargo-supply-chain
          cargo-sort
          cargo-udeps
        ]
        ++ optionals cfg.go
        [
          go
          golint
          delve
          golangci-lint
        ]
        ++ optionals cfg.cpp
        [
          lldb
          clang
          clang-tools
        ]
        ++ optionals cfg.typescript
        [
          nodePackages_latest.nodejs
          eslint
          nodePackages_latest.yarn
          nodePackages_latest.prettier
          nodePackages_latest.typescript
        ]
        ++ optionals cfg.steel [steel];

      sessionVariables = mkMerge [
        (mkIf cfg.rust {
          RUSTUP_HOME = mkDefault "${stateHome}/rustup";
          CARGO_HOME = mkDefault "${stateHome}/cargo";
          CARGO_INSTALL_ROOT = mkDefault "${dataHome}/bin";
        })

        (mkIf cfg.go {
          GOPATH = mkDefault "${dataHome}/go";
          GOCACHE = mkDefault "${cacheHome}/go/build";
          GOMODCACHE = mkDefault "${cacheHome}/go/mod";
        })

        (mkIf cfg.steel {
          STEEL_LSP_HOME = "${stateHome}/steel-lsp-server";
        })
      ];

      sessionPath =
        ["${dataHome}/bin"]
        ++ optional cfg.go
        "${config.home.sessionVariables.GOPATH}/bin";
    };

    aftix = {
      shell = {
        development = true;

        upgradeCommands =
          optionals cfg.rust
          [
            "rustup update"
          ];

        neededDirs = with config.home.sessionVariables; (
          ["${dataHome}/bin"]
          ++ optionals cfg.go
          [GOPATH GOCACHE GOMODCACHE]
          ++ optional cfg.rust
          CARGO_HOME
        );
      };

      development.nixdConfig = lib.mkIf cfg.nix {
        formatting.command = ["alejandra"];
      };
    };

    programs.gh = {
      enable = cfg.gh;

      settings = {
        git_protocol = "ssh";
        prompt = "true";
        aliases.co = "pr checkout";
      };
    };

    xdg.configFile = mkMerge [
      (mkIf cfg.typescript {
        "npm/npmrc".source = (pkgs.formats.keyValue {}).generate "npm" {
          prefix = "\${XDG_DATA_HOME}/npm";
          cache = "\${XDG_CACHE_HOME}/npm";
          init-module = "\${XDG_CONFIG_HOME}/npm/config/npm-init.js";
          logs-dir = "\${XDG_CACHE_HOME}/npm/logs";
        };
      })
    ];
  };
}
