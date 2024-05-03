{
  upkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf mkDefault;
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
      packages = with upkgs; (
        [
          shellcheck
          gnupatch
          gnumake
          gawk
        ]
        ++ (
          if cfg.nix
          then [statix alejandra]
          else []
        )
        ++ (
          if cfg.rust
          then
            ([
                rustup
                sccache
                cargo-nextest
                cargo-supply-chain
                cargo-update
                cargo-sort
                cargo-udeps
                cargo-crev
              ]
              ++ (
                if upkgs.system == "x86_64-linux"
                then [cargo-llvm-cov]
                else []
              ))
          else []
        )
        ++ (
          if cfg.go
          then [
            go
            golint
            delve
            golangci-lint
          ]
          else []
        )
        ++ (
          if cfg.cpp
          then [
            lldb
            clang
            clang-tools
          ]
          else []
        )
        ++ (
          if cfg.typescript
          then [
            nodePackages_latest.nodejs
            nodePackages_latest.eslint
            nodePackages_latest.yarn
            nodePackages_latest.prettier
            nodePackages_latest.typescript
          ]
          else []
        )
      );

      sessionVariables = {
        RUSTC_WRAPPER = mkIf cfg.rust (mkDefault "${upkgs.sccache}/bin/sccache");
        RUSTUP_HOME = mkIf cfg.rust (mkDefault "${stateHome}/rustup");
        CARGO_HOME = mkIf cfg.rust (mkDefault "${stateHome}/cargo");
        CARGO_INSTALL_ROOT = mkIf cfg.rust (mkDefault "${dataHome}/bin");
        GOPATH = mkIf cfg.go (mkDefault "${dataHome}/go");
        GOCACHE = mkIf cfg.go (mkDefault "${cacheHome}/go/build");
        GOMODCACHE = mkIf cfg.go (mkDefault "${cacheHome}/go/mod");
      };

      sessionPath =
        ["${dataHome}/bin"]
        ++ (
          if cfg.go
          then [
            "${config.home.sessionVariables.GOPATH}/bin"
          ]
          else []
        );
    };

    my.shell = {
      elvish.development = true;

      upgradeCommands =
        if cfg.rust
        then [
          "rustup update"
          "cargo install-update --all"
        ]
        else [];

      neededDirs = with config.home.sessionVariables; (
        ["${dataHome}/bin"]
        ++ (
          if cfg.go
          then [GOPATH GOCACHE GOMODCACHE]
          else []
        )
        ++ (
          if cfg.rust
          then [CARGO_HOME]
          else []
        )
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

    systemd.user.services.linkGh = let
      cDir = "${config.home.homeDirectory}/.config";
      share = "${config.home.homeDirectory}/.local/share";
    in
      mkIf cfg.gh {
        Unit.Description = "Link gh hosts file";
        Service = {
          Type = "oneshot";
          ExecStart = ''
            ${upkgs.coreutils}/bin/mkdir -p "${cDir}/gh" ; \
            ${upkgs.coreutils}/bin/ln -sf "${share}/gh/hosts.yml" "${cDir}/gh/hosts.yml"
          '';
        };
        Install.WantedBy = ["default.target"];
      };

    xdg.configFile."npm/npmrc".source = mkIf cfg.typescript ((upkgs.formats.keyValue {}).generate "npm" {
      prefix = "\${XDG_DATA_HOME}/npm";
      cache = "\${XDG_CACHE_HOME}/npm";
      init-module = "\${XDG_CONFIG_HOME}/npm/config/npm-init.js";
      logs-dir = "\${XDG_CACHE_HOME}/npm/logs";
    });
  };
}
