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
    ../../host/common/statics.nix

    ./bash.nix
    ./documentation.nix
    ./elvish.nix
    ./gnupg.nix
    ./nushell.nix
    ./python.nix
    ./swayosd.nix
    ./shell.nix
    ./tldr.nix
    ./xdg.nix
    ./zsh.nix
  ];

  options.my = {
    matrixClient = mkOption {
      default = null;

      type = with lib.types; nullOr package;
    };
  };

  config = {
    nix.settings.use-xdg-base-directories = true;

    home = {
      language.base = mkDefault "en_US";

      packages = with pkgs;
        [
          aspell
          aspellDicts.en
          aspellDicts.en-science
          aspellDicts.en-computers

          jq
          # nix-doc
          nix-tree
          manix
          sops
          age
          fzf
          micro

          xz
          zstd
          zlib
        ]
        ++ lib.optionals (config.my.matrixClient != null) [config.my.matrixClient];

      sessionVariables = {
        FZF_DEFAULT_OPTS = mkDefault "--layout=reverse --height 40%";

        CREDENTIALS_DIRECTORY = mkDefault "${dataHome}/systemd-creds";
        HISTFILE = mkDefault "${stateHome}/bash/history";
        LESSHISTFILE = mkDefault "-";

        EDITOR = mkDefault "micro";
        MANPAGER = mkDefault "${lib.getExe pkgs.less}";
        PAGER = mkDefault "${lib.getExe pkgs.less}";
        VISUAL = mkDefault "micro";
      };

      sessionPath = [
        "${configHome}/bin"
        "${stateHome}/nix/profiles/home-manager/home-path/bin"
      ];
    };

    gtk.gtk2.configLocation = "${configHome}/gtk-2.0/gtkrc";
    xresources.properties = mkForce null;

    programs.home-manager.enable = true;

    services.ssh-agent.enable = lib.strings.hasSuffix "-linux" pkgs.system;
    systemd.user.startServices = true;
  };
}
