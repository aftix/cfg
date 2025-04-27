{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib.attrsets) mergeAttrsList;
  inherit (lib.strings) escapeShellArg hasPrefix optionalString concatMapStringsSep;
  inherit (lib.lists) optionals;
  inherit (config.xdg) stateHome cacheHome;
  cfg = config.my.shell;
in {
  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";

    defaultKeymap = "viins";
    autocd = true;

    initContent = let
      neededDirs = concatMapStringsSep "\n" (path: "mkdir -p " + escapeShellArg path) cfg.neededDirs;

      homebrewPath = let
        brewPath =
          if hasPrefix "x86_64" pkgs.system
          then "/usr/local/bin/brew"
          else "/opt/homebrew/bin/brew";
      in
        optionalString cfg.addHomebrewPath
        ''
          # Add homebrew prefix to path
          export PATH="$(${brewPath} --prefix)/bin:$PATH"

          # Add homebrew environmental variables
          source <(brew shellenv)
        '';

      envFiles = concatMapStringsSep "\n" (path: let p = escapeShellArg path; in "[[ -f ${p} ]] && source ${p}") cfg.extraEnvFiles;
      fixGpg =
        optionalString cfg.gpgTtyFix
        ''
          # Fix gpg pinentry
          export GPG_TTY="$(tty)"
        '';
      fixXterm =
        optionalString cfg.xtermFix
        /*
        zsh
        */
        ''
          # Fix xterm variants for ssh, etc
          [[ "$TERM" =~ ^xterm- || -z "$TERM" ]] && export TERM="xterm"
          export TERMINAL="$TERM"
        '';

      starshipInit = optionalString config.programs.starship.enable "source <(starship init zsh)";
    in
      /*
      zsh
      */
      ''
        ${neededDirs}

        ${
          optionalString config.services.ssh-agent.enable
          "export SSH_AUTH_SOCK=\"$XDG_RUNTIME_DIR/ssh-agent\""
        }

        ${envFiles}

        ${homebrewPath}

        ${fixGpg}
        ${fixXterm}

        # Disable ^S and ^Q
        stty -ixon

        # Load carapace completions
        which carapace >/dev/null 2>&1 && source <(carapace _carapace zsh)

        ${starshipInit}

        upgrade () {
        ${builtins.concatStringsSep "\n" cfg.upgradeCommands}
        }
      '';

    shellAliases = mergeAttrsList (
      builtins.map ({
        name,
        command,
        ...
      }: {${name} = command;})
      cfg.aliases
      ++ optionals cfg.development
      [
        {
          name = "k";
          command = "make -j$(nproc)";
        }
        {
          name = "kd";
          command = "make DEBUG=yes -j$(nproc)";
        }
      ]
    );

    history.path = "${stateHome}/zsh/history";
    historySubstringSearch.enable = true;
  };

  home = {
    file."${cacheHome}/zsh/.keep".text = "";
    sessionVariables.ZSH_CACHE_DIR = cacheHome + "/zsh";
  };
}
