{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib) mkDefault;
  inherit (config.xdg) configHome dataHome stateHome;
in {
  imports = [
    ./mylib.nix

    ./documentation.nix
    ./elvish.nix
    ./gnupg.nix
    ./python.nix
    ./shell.nix
    ./tldr.nix
    ./xdg.nix
  ];

  options.my.registerMimes = mkOption {default = true;};

  config = {
    home = {
      language.base = mkDefault "en_US";

      packages = with pkgs; [
        aspell
        aspellDicts.en
        aspellDicts.en-science
        aspellDicts.en-computers

        jq
        nix-doc
        manix
        sops
        age
        fzf

        xz
        zstd
        zlib
      ];

      sessionVariables = {
        FZF_DEFAULT_OPTS = mkDefault "--layout=reverse --height 40%";
        LESSHISTFILE = mkDefault "-";
        HISTFILE = mkDefault "${stateHome}/bash/history";
        PAGER = mkDefault "${pkgs.coreutils}/bin/less";
        MANPAGER = mkDefault "${pkgs.coreutils}/bin/less";
        CREDENTIALS_DIRECTORY = mkDefault "${dataHome}/systemd-creds";
        ZDOTDIR = mkDefault "${configHome}/zsh";
      };

      sessionPath = [
        "${configHome}/bin"
        "${stateHome}/nix/profiles/home-manager/home-path/bin"
      ];
    };

    programs.home-manager.enable = true;
    services.ssh-agent.enable = pkgs.system == "x86_64-linux";
    systemd.user.startServices = true;
  };
}
