{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib) mkDefault mkForce;
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
    nix.settings.use-xdg-base-directories = true;

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

        CREDENTIALS_DIRECTORY = mkDefault "${dataHome}/systemd-creds";
        HISTFILE = mkDefault "${stateHome}/bash/history";
        LESSHISTFILE = mkDefault "-";
        ZDOTDIR = mkDefault "${configHome}/zsh";

        PAGER = mkDefault "${pkgs.coreutils}/bin/less";
        MANPAGER = mkDefault "${pkgs.coreutils}/bin/less";
      };

      sessionPath = [
        "${configHome}/bin"
        "${stateHome}/nix/profiles/home-manager/home-path/bin"
      ];
    };

    gtk.gtk2.configLocation = "${configHome}/gtk-2.0/gtkrc";
    xresources.properties = mkForce null;

    programs = {
      home-manager.enable = true;

      nix-index-database.comma.enable = true;
      command-not-found.enable = false;
    };

    services.ssh-agent.enable = pkgs.system == "x86_64-linux";
    systemd.user.startServices = true;
  };
}
