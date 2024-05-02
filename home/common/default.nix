{
  lib,
  config,
  upkgs,
  ...
}: let
  inherit (lib.options) mkOption;
in {
  imports = [
    ./documentation.nix
    ./gnupg.nix
    ./python.nix
    ./tldr.nix
    ./xdg.nix
  ];

  options.my.registerMimes = mkOption {default = true;};

  config = {
    home = {
      packages = with upkgs; [
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

      sessionVariables = let
        hDir = config.home.homeDirectory;
      in {
        LESSHISTFILE = lib.mkDefault "-";
        HISTFILE = lib.mkDefault "${hDir}/.local/state/bash/history";
      };
    };

    programs = {
      home-manager.enable = true;
      starship = {
        enable = true;
        settings = {
          "$schema" = "https://starship.rs/config-schema.json";
          add_newline = true;
          package.disabled = true;
        };
      };
    };

    services.ssh-agent.enable = upkgs.system == "x86_64-linux";

    systemd.user = {
      startServices = true;
    };
  };
}
