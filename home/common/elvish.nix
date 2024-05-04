{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib.attrsets) mapAttrsToList mergeAttrsList;
  inherit (lib.strings) escapeShellArg hasPrefix;
  shellCfg = config.my.shell;
  cfg = shellCfg.elvish;
in {
  home.packages = lib.mkIf cfg.enable [pkgs.elvish];

  xdg.configFile =
    {
      "elvish/rc.elv".text = let
        pathsToAdd = builtins.concatStringsSep " " (builtins.map escapeShellArg config.home.sessionPath);
        homebrewPath = let
          brewPath =
            if hasPrefix "x86_64" pkgs.system
            then "/usr/local/bin/brew"
            else "/opt/homebrew/bin/brew";
        in
          if shellCfg.addHomebrewPath
          then ''
            # Add homebrew prefix to path
            add_to_path (${brewPath} --prefix)\"/bin\"
            # Add homebrew environmental variables
            eval (^
              brew shellenv |^
              grep -v "PATH" |^
              each {|l| re:replace '^export' 'set-env' $l} |^
              each {|l| re:replace '=' ' ' $l} |^
              each {|l| re:replace '$;' \'\' $l} |^
              to-terminated " "^
            )
          ''
          else "";

        setEnvVars = vars:
          builtins.concatStringsSep "\n" (
            mapAttrsToList (name: val: "set-env ${escapeShellArg name} ${escapeShellArg val}") vars
          );
        xdgBases = with config.xdg; {
          XDG_CONFIG_HOME = configHome;
          XDG_DATA_HOME = dataHome;
          XDG_CACHE_HOME = cacheHome;
          XDG_STATE_HOME = stateHome;
        };
        createXdgBases = builtins.concatStringsSep "\n" (mapAttrsToList (_: val: ''
            mkdir -p ${escapeShellArg val}
          '')
          xdgBases);

        setXdgBases = let
          base = setEnvVars xdgBases;
        in
          if pkgs.system == "x86_64-linux"
          then ''
            ${base}
            if (not (has-env XDG_RUNTIME_DIR)) {
              set-env XDG_RUNTIME_DIR /run/user/$E:EUID
            }
          ''
          else base;
        setSessionVars = setEnvVars config.home.sessionVariables;
        setLocaleVars = setEnvVars shellCfg.shellLocale;

        createExtraDirs = builtins.concatStringsSep "\n" (builtins.map
          (path: "mkdir -p ${escapeShellArg path}")
          shellCfg.neededDirs);
        sourceExtraEnv = builtins.concatStringsSep "\n" (builtins.map (
            path: let
              p = escapeShellArg path;
            in ''
              if (and (os:exists ${p}) (os:is-regular ${p}) (not (os:is-dir ${p}))) {
                from-lines < ${p} | peach {|line|
                  if ?(grep -q '^#' (slurp < $line)) {
                    break
                  }

                  var fields = [(str:split "=" $line)]
                  if (== (count $fields) 2) {
                    echo "set-env "$fields[0]" "$fields[1] | eval (slurp)
                  }
                }
              }
            ''
          )
          shellCfg.extraEnvFiles);

        historyHook =
          if cfg.fastForwardHook
          then ''
            # Before every command prompt is presented, fast forward the shell command history from other sessions
            set edit:before-readline = [
              {
                edit:history:fast-forward }
              $@edit:before-readline
            ]
          ''
          else "";

        importMods = builtins.concatStringsSep "\n" (builtins.map (
            {
              name,
              enable ? true,
              ...
            }:
              if enable
              then "use " + name
              else ""
          )
          cfg.extraMods);

        fixGpg =
          if shellCfg.gpgTtyFix
          then ''
            # Fix gpg pinentry
            set-env GPG_TTY (tty)
          ''
          else "";
        fixXterm =
          if shellCfg.xtermFix
          then ''
            # Fix xterm variants for ssh, etc
            if (re:match '^xterm-' $E:TERM) {
              set-env TERM "xterm"
            } elif (not (has-env TERM)) {
              set-env TERM "xterm"
            }
            set-env TERMINAL $E:TERM
          ''
          else "";

        condaMod =
          if cfg.conda.enable
          then ''
            # Add conda elvish module
            use mamba
            set mamba:cmd = ${cfg.conda.condaCmd}
            set mamba:root = ${escapeShellArg cfg.conda.condaRoot}
          ''
          else "";

        aliases = builtins.concatStringsSep "\n" (builtins.map ({
            name,
            command,
            completer ? "",
            external ? false,
          }: let
            cmd =
              if external
              then "e:${command}"
              else command;
            completion =
              if builtins.isAttrs completer
              then let
                arguments =
                  if builtins.hasAttr "arguments" completer
                  then "|${completer.arguments}|"
                  else "";
              in
                ''
                  fn ${completer.name} {${arguments}
                    ${completer.body}
                  }
                  set edit:completion:arg-completer[${escapeShellArg name}] = $''
                + "${completer.name}~"
              else if completer != ""
              then ''
                if (has-key $edit:completion:arg-completer ${completer}) {
                  set edit:completion:arg-completer[${escapeShellArg name}] = $edit:completion:arg-completer[${completer}]
                }
              ''
              else "";
          in ''
            fn ${name} {|@rest| ${cmd} $@rest}
            ${completion}
          '')
          shellCfg.aliases);

        functions = builtins.concatStringsSep "\n" (builtins.map (
            {
              name,
              arguments ? "",
              body,
            }: let
              args =
                if arguments != ""
                then "|${arguments}|"
                else "";
            in ''
              fn ${name} {${args}
                ${body}
              }
            ''
          )
          cfg.extraFunctions);

        devInit =
          if cfg.development
          then ''
            # Setup development aliases

            set edit:completion:arg-completer[k] = $edit:completion:arg-completer[make]
            set edit:completion:arg-completer[kd] = $edit:completion:arg-completer[make]
            fn k {|@rest| e:make -j(nproc) $@rest}
            fn kd {|@rest| e:make DEBUG=yes -j(nproc) $@rest}
          ''
          else "";
        starshipInit =
          if config.programs.starship.enable
          then "eval (e:starship init elvish)"
          else "";
      in ''
        # File generated my Home Manager. DO NOT EDIT
        use re
        use str
        use path
        use os

        fn add_to_path {
          |@my_paths|
          set paths = [(each {
            |my_path|
            if (not (has-value [(each {|p| ==s $my_path $p} $paths)] 0)) {
              put $my_path
            }
          } $my_paths) $@paths]
        }
        # Add home.sessionPath paths to the PATH variable
        add_to_path ${pathsToAdd}
        ${homebrewPath}

        # Set the xdg base directory variables
        ${setXdgBases}

        # Set locale environmental variables
        ${setLocaleVars}

        # Add home.sessionVariables to elvish interactive environment
        ${setSessionVars}

        # Create XDG base directories
        ${createXdgBases}

        # Create extra directories
        ${createExtraDirs}

        # Source extra environment files
        ${sourceExtraEnv}

        # Setup carapace completions
        if (has-external carapace) {
          eval (e:carapace _carapace | slurp )
        }

        ${historyHook}

        # Import modules
        ${importMods}

        # Disable ^S and ^q
        stty -ixon

        ${fixGpg}
        ${fixXterm}
        ${condaMod}

        # Shell Aliases
        ${aliases}

        ${devInit}

        # Extra functions
        ${functions}

        # Setup common modules
        use completions/molecule
        use completions/crev
        use jump
        use iterm2
        set edit:completion:arg-completer[tldr] = $edit:completion:arg-completer[tealdeer]

        fn add_bookmark {|@args| jump:add_bookmark $@args }
        fn remove_bookmark {|@args| jump:remove_bookmark $@args }
        fn jump {|@args| jump:jump $@args }
        fn cd {|@args| jump:jump $@args }

        ${
          if config.services.ssh-agent.enable
          then "set-env SSH_AUTH_SOCK (path:join $E:XDG_RUNTIME_DIR ssh-agent)"
          else ""
        }

        fn upgrade {
          ${builtins.concatStringsSep "\n" shellCfg.upgradeCommands}
        }

        ${starshipInit}
        iterm2:init
        if (has-external nh) {
          e:nh completions --shell elvish | eval (slurp)
        }

        # Extra config
        ${cfg.extraConfig}
      '';

      # Link raw elvish modules into elvish/lib
      "elvish/lib/jump.elv".source = ./_external.elvish/lib/jump.elv;
      "elvish/lib/iterm2.elv".source = ./_external.elvish/lib/iterm2.elv;
      "elvish/lib/cmds.elv".source = ./_external.elvish/lib/cmds.elv;
      "elvish/lib/mamba.elv".source = ./_external.elvish/lib/mamba.elv;
      "elvish/lib/completions/crev.elv".source = ./_external.elvish/lib/completions/crev.elv;
      "elvish/lib/completions/molecule.elv".source = ./_external.elvish/lib/completions/molecule.elv;
    }
    // mergeAttrsList (builtins.map ({
      name,
      source,
      ...
    }: {"elvish/${name}".source = source;})
    cfg.extraMods);
}
