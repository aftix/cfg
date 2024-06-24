{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib.attrsets) mapAttrsToList mergeAttrsList optionalAttrs;
  inherit (lib.strings) escapeShellArg hasPrefix optionalString concatMapStringsSep;
  shellCfg = config.my.shell;
  cfg = shellCfg.elvish;
in {
  home.packages = lib.mkIf cfg.enable [pkgs.elvish];

  my.docs.pages.elvish = let
    inherit (config.my.lib) mergeTagged;
  in {
    _docsName = "Extra shell functions and modules for elvish";
    _docsExtraSections =
      {
        Functions = mergeTagged (builtins.map ({
            name,
            body,
            docs ? "",
            ...
          }: {
            tag = name;
            content =
              if docs == ""
              then body
              else docs;
          })
          (builtins.filter ({docs ? "", ...}: builtins.isString docs) cfg.extraFunctions));
      }
      // optionalAttrs
      shellCfg.development
      {
        Aliases = mergeTagged [
          {
            tag = "k";
            content = "make -j(nproc)";
          }
          {
            tag = "kd";
            content = "make -j(nproc) DEBUG=yes";
          }
        ];
      };

    _docsSeeAlso = let
      inherit (config.my.docs) prefix;
    in [
      {
        name = prefix + "-shell";
        mansection = 7;
      }
    ];
  };

  xdg.configFile =
    {
      "elvish/rc.elv".text = let
        pathsToAdd = concatMapStringsSep " " escapeShellArg config.home.sessionPath;
        homebrewPath = let
          brewPath =
            if hasPrefix "x86_64" pkgs.system
            then "/usr/local/bin/brew"
            else "/opt/homebrew/bin/brew";
        in
          optionalString shellCfg.addHomebrewPath
          /*
          elvish
          */
          ''
            # Add homebrew prefix to path
            add_to_path (${brewPath} --prefix)'/bin'
            # Add homebrew environmental variables
            eval (brew shellenv | grep -v "PATH" | each {|l| re:replace 'export' 'set-env' $l} | each {|l| re:replace '=' ' ' $l} | each {|l| re:replace '$;' "" $l} | to-terminated " ")
          '';

        setEnvVars = vars:
          builtins.concatStringsSep "\n" (
            mapAttrsToList (name: val: "set-env ${escapeShellArg name} ${escapeShellArg val}") vars
          );

        setXdgBases = let
          base = setEnvVars (with config.xdg; {
            XDG_CONFIG_HOME = configHome;
            XDG_DATA_HOME = dataHome;
            XDG_CACHE_HOME = cacheHome;
            XDG_STATE_HOME = stateHome;
          });
        in
          if lib.strings.hasSuffix "-linux" pkgs.system
          then
            /*
            elvish
            */
            ''
              ${base}
              if (not (has-env XDG_RUNTIME_DIR)) {
                set-env XDG_RUNTIME_DIR /run/user/$E:EUID
              }
            ''
          else base;
        setSessionVars = setEnvVars config.home.sessionVariables;
        setLocaleVars = setEnvVars shellCfg.shellLocale;

        createExtraDirs =
          concatMapStringsSep "\n"
          (path: "mkdir -p " + escapeShellArg path)
          shellCfg.neededDirs;
        sourceExtraEnv =
          concatMapStringsSep "\n" (
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
          shellCfg.extraEnvFiles;

        historyHook =
          optionalString cfg.fastForwardHook
          /*
          elvish
          */
          ''
            # Before every command prompt is presented, fast forward the shell command history from other sessions
            set edit:before-readline = [
              {
                edit:history:fast-forward }
              $@edit:before-readline
            ]
          '';

        importMods =
          concatMapStringsSep "\n" (
            {
              name,
              enable ? true,
              ...
            }:
              optionalString enable ("use " + name)
          )
          cfg.extraMods;

        fixGpg =
          optionalString shellCfg.gpgTtyFix
          /*
          elvish
          */
          ''
            # Fix gpg pinentry
            set-env GPG_TTY (tty)
          '';
        fixXterm =
          optionalString shellCfg.xtermFix
          /*
          elvish
          */
          ''
            # Fix xterm variants for ssh, etc
            if (re:match '^xterm-' $E:TERM) {
              set-env TERM "xterm"
            } elif (not (has-env TERM)) {
              set-env TERM "xterm"
            }
            set-env TERMINAL $E:TERM
          '';

        condaMod =
          optionalString cfg.conda.enable
          /*
          elvish
          */
          ''
            # Add conda elvish module
            use mamba
            set mamba:cmd = ${cfg.conda.condaCmd}
            set mamba:root = ${escapeShellArg cfg.conda.condaRoot}
          '';

        aliases = concatMapStringsSep "\n" ({
          name,
          command,
          completer ? "",
          external ? false,
          ...
        }: let
          cmd =
            (optionalString external "e:") + command;
          completion =
            if builtins.isAttrs completer
            then let
              arguments =
                optionalString (builtins.hasAttr "arguments" completer)
                "|${completer.arguments}|";
            in
              /*
              elvish
              */
              ''
                fn ${completer.name} {${arguments}
                  ${completer.body}
                }
                set edit:completion:arg-completer[${escapeShellArg name}] = $''
              + "${completer.name}~"
            else
              optionalString (completer != "")
              /*
              elvish
              */
              ''
                if (has-key $edit:completion:arg-completer ${completer}) {
                  set edit:completion:arg-completer[${escapeShellArg name}] = $edit:completion:arg-completer[${completer}]
                }
              '';
        in
          /*
          elvish
          */
          ''
            fn ${name} {|@rest| ${cmd} $@rest}
            ${completion}
          '')
        shellCfg.aliases;

        functions =
          concatMapStringsSep "\n" (
            {
              name,
              arguments ? "",
              body,
              ...
            }: let
              args =
                optionalString (arguments != "")
                "|${arguments}|";
            in
              /*
              elvish
              */
              ''
                fn ${name} {${args}
                  ${body}
                }
              ''
          )
          cfg.extraFunctions;

        devInit =
          optionalString shellCfg.development
          /*
          elvish
          */
          ''
            # Setup development aliases

            set edit:completion:arg-completer[k] = $edit:completion:arg-completer[make]
            set edit:completion:arg-completer[kd] = $edit:completion:arg-completer[make]
            fn k {|@rest| e:make -j(nproc) $@rest}
            fn kd {|@rest| e:make DEBUG=yes -j(nproc) $@rest}
          '';
        starshipInit =
          optionalString config.programs.starship.enable
          /*
          elvish
          */
          "eval (e:starship init elvish)";
      in
        /*
        elvish
        */
        ''
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

          # Disable ^S and ^Q
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
            optionalString config.services.ssh-agent.enable "set-env SSH_AUTH_SOCK (path:join $E:XDG_RUNTIME_DIR ssh-agent)"
          }

          fn upgrade {
            ${builtins.concatStringsSep "\n" shellCfg.upgradeCommands}
          }

          ${starshipInit}
          iterm2:init

          # Extra completions
          ${builtins.concatStringsSep "\n" cfg.extraCompletions}

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
