{
  upkgs,
  lib,
  config,
  ...
}: let
  cfg = config.my.development;
  inherit (lib.options) mkOption;
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

      sessionVariables = let
        hDir = config.home.homeDirectory;
      in {
        RUSTUP_HOME = lib.mkIf cfg.rust "${hDir}/.local/state/rustup";
        CARGO_HOME = lib.mkIf cfg.rust "${hDir}/.local/state/rustup";
        CARGO_INSTALL_ROOT = lib.mkIf cfg.rust "${hDir}/.local/state/rustup";
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

    systemd.user.services.linkGh = let
      cDir = "${config.home.homeDirectory}/.config";
      share = "${config.home.homeDirectory}/.local/share";
    in
      lib.mkIf cfg.gh {
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

    xdg.configFile."npm/npmrc".source = lib.mkIf cfg.typescript ((upkgs.formats.keyValue {}).generate "npm" {
      prefix = "\${XDG_DATA_HOME}/npm";
      cache = "\${XDG_CACHE_HOME}/npm";
      init-module = "\${XDG_CONFIG_HOME}/npm/config/npm-init.js";
      logs-dir = "\${XDG_CACHE_HOME}/npm/logs";
    });
  };
}
