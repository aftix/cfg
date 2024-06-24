{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib.attrsets) mergeAttrsList;
  inherit (lib.strings) escapeShellArg hasPrefix optionalString concatMapStringsSep;
  inherit (lib.lists) optionals;
  cfg = config.my.shell;
in {
  programs.bash = {
    enable = true;
    enableCompletion = true;
    historyFile = config.home.sessionVariables.HISTFILE;

    bashrcExtra = let
      homebrewPath = let
        brewPath =
          if hasPrefix "x86_64" pkgs.system
          then "/usr/local/bin/brew"
          else "/opt/homebrew/bin/brew";
      in
        optionalString cfg.addHomebrewPath
        /*
        bash
        */
        ''
          # Add homebrew prefix to path
          export PATH="$(${brewPath} --prefix)/bin:$PATH"

          # Add homebrew environmental variables
          source <(brew shellenv)
        '';

      envFiles = concatMapStringsSep "\n" (path: let p = escapeShellArg path; in "[[ -f ${p} ]] && source ${p}") cfg.extraEnvFiles;
    in
      /*
      bash
      */
      ''
        ${
          optionalString config.services.ssh-agent.enable
          "export SSH_AUTH_SOCK=\"$XDG_RUNTIME_DIR/ssh-agent\""
        }

        ${envFiles}

        ${homebrewPath}

        upgrade () {
        ${builtins.concatStringsSep "\n" cfg.upgradeCommands}
        }
      '';

    initExtra = let
      neededDirs = concatMapStringsSep "\n" (path: "mkdir -p " + escapeShellArg path) cfg.neededDirs;

      fixGpg =
        optionalString cfg.gpgTtyFix
        ''
          # Fix gpg pinentry
          export GPG_TTY="$(tty)"
        '';

      fixXterm =
        optionalString cfg.xtermFix
        ''
          # Fix xterm variants for ssh, etc
          [[ "$TERM" =~ ^xterm- || -z "$TERM" ]] && export TERM="xterm"
          export TERMINAL="$TERM"
        '';

      starshipInit = optionalString config.programs.starship.enable "source <(starship init bash)";
    in
      /*
      bash
      */
      ''
        ${neededDirs}

        ${fixGpg}
        ${fixXterm}

        # Disable ^S and ^Q
        stty -ixon

        # Load carapace completions
        which carapace >/dev/null 2>&1 && source <(carapace _carapace bash)

        ${starshipInit}
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
  };
}
