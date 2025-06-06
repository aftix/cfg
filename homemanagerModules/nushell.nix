# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib.attrsets) optionalAttrs mergeAttrsList;
  inherit (lib.strings) hasPrefix optionalString concatMapStringsSep concatLines;
  shellCfg = config.aftix.shell;
  cfg = shellCfg.nushell;
in {
  home.packages = lib.mkIf cfg.enable ([pkgs.nushell] ++ cfg.plugins);

  aftix.docs.pages.nushell = let
    inherit (pkgs.aftixLib) mergeTagged;
  in {
    _docsName = "Extra shell functions and modules for nushell";
    _docsExtraSections =
      {
        ExtraCommands = mergeTagged (builtins.map ({
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
          (builtins.filter ({docs ? "", ...}: builtins.isString docs) cfg.extraCommands));
        Plugins = mergeTagged (builtins.map (pkg: {
            tag = "${lib.strings.getName pkg} (${lib.strings.getVersion pkg})";
            content = let
              desc =
                pkg.meta.description or "No description available.";
              homepage = pkg.meta.homepage or "No homepage available.";
              license =
                if pkg.meta ? license
                then "${pkg.meta.license.fullName or pkg.meta.license.shortName} (${pkg.meta.license.url or "no url available"})"
                else "No license available";
            in ''
              Description: ${desc}

              Homepage: ${homepage}

              License: ${license}
            '';
          })
          cfg.plugins);
      }
      // optionalAttrs shellCfg.development {
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
      inherit (config.aftix.docs) prefix;
    in [
      {
        name = prefix + "-shell";
        mansection = 7;
      }
    ];
  };

  xdg.configFile = lib.mkIf cfg.enable (
    {
      "nushell/env.nu".text = let
        setEnvVars = vars: "load-env ${builtins.toJSON vars}\n";

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
            nu
            */
            ''
              ${base}
              if $env.XDG_RUNTIME_DIR? == null or $env.XDG_RUNTIME_DIR == "" {
                $env.XDG_RUNTIME_DIR = $"/run/user/$env.EUID"
              }
            ''
          else base;

        addPlugins = concatLines (builtins.map (
            pkg:
            /*
            nu
            */
            ''
              try {
                plugin add ${lib.meta.getExe pkg}
              }
            ''
          )
          cfg.plugins);

        homebrewPath = let
          brewPath =
            if hasPrefix "x86_64" pkgs.system
            then "/usr/local/bin/brew"
            else "/opt/homebrew/bin/brew";
        in
          optionalString shellCfg.addHomebrewPath
          /*
          nu
          */
          ''
            # Add homebrew prefix to path
            $env.PATH = ($env.PATH | prepend $"(${brewPath} --prefix)/bin")
            # Add homebrew environmental variables
            (brew shellenv
              | lines
              | find -v PATH
              | str replace -r '^export' ""
              | str replace -r '(\w+|");\w*$' '$1'
              | str trim
              | each { split column --number 2 '=' }
              | each { {$in.0.column1: $in.0.column2} }
              | reduce {|it, acc| $acc | merge $it}
              | load-env
            )
          '';
        addedPaths = concatLines (builtins.map (p:
          /*
          nu
          */
          ''
            $env.PATH = ($env.PATH | append r#'${p}'#)
          '')
        config.home.sessionPath);
        sourceExtraEnv = concatLines (builtins.map (
            path: let
              p = "r#'${path}'#";
            in
              /*
              nu
              */
              ''
                if (${p} | path expand | path type) == file {
                  try {
                    (open (${p} | path expand)
                      | lines
                      | find -v PATH
                      | find -r '^(export\w)?\w*[a-zA-Z]+'
                      | find -r '=.+$ '
                      | str replace -r '^export' ""
                      | str replace -r '\w+;\w+$' ""
                      | str trim
                      | each { split column --number 2 '=' }
                      | each { {$in.0.column1: $in.0.column2} }
                      | reduce {|it, acc| $acc | merge $it}
                      | load-env
                    )
                  }
                }
              ''
          )
          shellCfg.extraEnvFiles);

        starshipInit =
          optionalString config.programs.starship.enable
          /*
          nu
          */
          ''
            # Enable the starship shell prompt
            mkdir r#'${config.xdg.cacheHome}/starship'#
            starship init nu | save --force r#'${config.xdg.cacheHome}/starship/init.nu'#
          '';

        fixSshAgent =
          optionalString config.services.ssh-agent.enable
          /*
          nu
          */
          ''
            $env.SSH_AUTH_SOCK = $env.XDG_RUNTIME_DIR ++ '/ssh-agent'
          '';
      in
        /*
        nu
        */
        ''
          # File generated by Home Manager. DO NOT EDIT

          # Set some configuration options
          $env.config = {
            show_banner: false
            rm: {always_trash: true}
            history: {file_format: sqlite}
            completions: {algorithm: fuzzy}
            use_kitty_protocol: ${
            if config.programs.kitty.enable
            then "true"
            else "false"
          }
          }

          # Setup the PATH environmental variable
          $env.PATH = ($env.PATH | split row (char esep))
          ${homebrewPath}
          ${addedPaths}

          # Set the xdg base directory variables
          ${setXdgBases}

          # Set locale environmental variables
          ${setEnvVars shellCfg.shellLocale}

          # Add home.sessionVariables to nushell environment
          ${setEnvVars config.home.sessionVariables}

          # Add plugins to registry
          ${addPlugins}


          ${fixSshAgent}

          # Setup carapace completions
          $env.CARAPACE_BRIDGES = 'zsh,fish,bash,ishellisense'
          if (which carapace | length) > 0 {
            mkdir r#'${config.xdg.cacheHome}/carapace'#
            carapace _carapace nushell | save --force r#'${config.xdg.cacheHome}/carapace/init.nu'#
          }

          ${starshipInit}

          # Source extra env files
          ${sourceExtraEnv}
        '';

      "nushell/config.nu".text = let
        fixGpg =
          optionalString shellCfg.gpgTtyFix
          /*
          nu
          */
          ''
            # Fix gpg pinentry
            $env.GPG_TTY = (tty)
          '';
        fixXterm =
          optionalString shellCfg.xtermFix
          /*
          nu
          */
          ''
            # Fix xterm variants for ssh, etc
            if $env.TERM =~ '^xterm-' {
              $env.TERM = 'xterm'
            } else if $env.TERM? == null or $env.TERM == "" {
              $env.TERM = 'xterm'
            }
            $env.TERMINAL = $env.TERM
          '';
        starshipInit =
          optionalString config.programs.starship.enable
          /*
          nu
          */
          ''
            # Enable starship shell prompt
            use ${config.xdg.cacheHome}/starship/init.nu
          '';
        importMods =
          concatMapStringsSep "\n" (
            {
              name,
              enable ? true,
              init ? "",
              extra ? "",
              ...
            }:
              optionalString enable
              /*
              nu
              */
              ''
                use ${config.xdg.configHome}/nushell/${name} ${extra}
                ${optionalString (init != "") init}
              ''
          )
          cfg.extraMods;

        createExtraDirs =
          concatMapStringsSep "\n"
          (path: "^mkdir -p r#'${path}'#")
          shellCfg.neededDirs;

        devInit =
          optionalString shellCfg.development
          /*
          nu
          */
          ''
            # Setup development aliases

            alias k = make -j(nproc)
            alias kd = make DEBUG=YES -j(nproc)
          '';

        aliases = concatLines (builtins.map ({
              name,
              command,
              external ? false,
              ...
            }:
            /*
            nu
            */
            ''
              alias ${name} = ${optionalString external "^"}${command}
            '')
          (builtins.filter ({name, ...}:
            # These aliases override the nice nu-integrated builtins, so ignore
            # just for nushell
              !builtins.elem name ["ls" "ll" "la" "mv" "du" "cp" "mkd"])
          shellCfg.aliases));

        extraCommands = concatLines (builtins.map ({
            name,
            arguments ? "",
            body,
            ...
          }:
          /*
          nu
          */
          ''
            def ${name} [${arguments}] {
              ${body}
            }
          '')
        cfg.extraCommands);
      in
        /*
        nu
        */
        ''
          # Create extra directories
          ${createExtraDirs}

          # Use additional modules
          ${importMods}

          # Shell Aliases
          ${aliases}

          # Extra commands
          ${extraCommands}

          def upgrade [] {
            ${concatLines shellCfg.upgradeCommands}
          }

          # Command to source .env files
          def --env source-bash-env [src] {
            if not ($src | path exists) {
              error make { msg: $"Path ($src) does not exist" }
            }

            if (realpath $src | path type) != 'file' {
              error make { msg: $"($src) is not a file"}
            }

            open $src --raw | lines | split column '=' --number 2 | each { {$in.column1: $in.column2} } | reduce {|it| merge $it} | load-env
          }

          ${devInit}

          # Setup carapace completions
          if (r#'${config.xdg.cacheHome}/carapace/init.nu'# | path expand | path type) == file {
            source r#'${config.xdg.cacheHome}/carapace/init.nu'#
          }

          # Disable ^S and ^Q
          stty -ixon
          ${fixGpg}
          ${fixXterm}

          ${starshipInit}

          use jump.nu *
          jump_init

          # Extra config
          ${cfg.extraConfig}
        '';

      "nushell/jump.nu".source = ./_external.nushell/jump.nu;
    }
    // mergeAttrsList (builtins.map ({
      name,
      source,
      enable ? true,
      ...
    }:
      optionalAttrs enable {"nushell/${name}".source = source;})
    cfg.extraMods)
  );
}
