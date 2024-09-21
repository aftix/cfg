{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf mkDefault mkMerge;
  inherit (lib.strings) hasSuffix;
  inherit (lib.lists) optional optionals;
  inherit (lib.options) mkOption;
  inherit (config.xdg) dataHome cacheHome stateHome;
  cfg = config.my.development;
in {
  imports = [./vcs.nix];

  options.my.development = {
    nix = mkOption {default = true;};
    rust = mkOption {default = true;};
    go = mkOption {default = true;};
    cpp = mkOption {default = true;};
    typescript = mkOption {default = true;};
    gh = mkOption {default = true;};
  };

  config = {
    home = {
      packages = with pkgs;
        [
          shellcheck
          gnupatch
          gnumake
          gawk
          just
        ]
        ++ optionals cfg.nix
        [statix alejandra nix-output-monitor nvd]
        ++ optionals cfg.rust
        [
          rustup
          sccache
          cargo-nextest
          cargo-supply-chain
          cargo-update
          cargo-sort
          cargo-udeps
          cargo-crev
        ]
        ++ optional
        (hasSuffix "-linux" pkgs.system && cfg.rust)
        cargo-llvm-cov
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
        ];

      sessionVariables = mkMerge [
        (mkIf cfg.rust {
          RUSTC_WRAPPER = mkDefault "${pkgs.sccache}/bin/sccache";
          RUSTUP_HOME = mkDefault "${stateHome}/rustup";
          CARGO_HOME = mkDefault "${stateHome}/cargo";
          CARGO_INSTALL_ROOT = mkDefault "${dataHome}/bin";
        })

        (mkIf cfg.go {
          GOPATH = mkDefault "${dataHome}/go";
          GOCACHE = mkDefault "${cacheHome}/go/build";
          GOMODCACHE = mkDefault "${cacheHome}/go/mod";
        })
      ];

      sessionPath =
        ["${dataHome}/bin"]
        ++ optional cfg.go
        "${config.home.sessionVariables.GOPATH}/bin";
    };

    my.shell = {
      development = true;

      upgradeCommands =
        optionals cfg.rust
        [
          "rustup update"
          "cargo install-update --all"
        ];

      neededDirs = with config.home.sessionVariables; (
        ["${dataHome}/bin"]
        ++ optionals cfg.go
        [GOPATH GOCACHE GOMODCACHE]
        ++ optional cfg.rust
        CARGO_HOME
      );
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
