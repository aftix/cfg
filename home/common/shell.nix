{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.lists) optional;
  inherit (lib.options) mkOption;
  cfg = config.my.shell;
in {
  options.my.shell = {
    aliases = mkOption {
      default = [];
      description = ''
        List of aliases, each alias being a set of {name, command}

        Can also contain an optional key 'completer' which is used for elvish to set the arg-completer
          if a string, will insert `set edit:completion:arg-completer[alias] = $edit:completion:arg-completer[completer]`
          if an attrset, will create a function from the attrset (same syntax as extraFunctions) and set that as completer

        Can also contain an optional key 'external' which will prepend the command with e: in elvish

        Can also contain an optional key 'docs' which will be substituted into the manual page for the host
          instead of the command. Set this to any non-string non-null value to skip documenting the alias
      '';
    };

    development = mkOption {
      default = false;
      description = "enable development aliases in shell rcs";
    };

    extraEnvFiles = mkOption {
      default = [];
      description = ''
        List of additional .env files to source. Must be solely setting environment variables.
        They do not need to exist (if a path does not exist, it is ignored)
      '';
    };

    addHomebrewPath = mkOption {
      default = false;
      description = "add `brew --prefix` to path";
    };

    neededDirs = mkOption {
      default = [];
      description = "List of directories to create with `mkdir -p` in shell rcs";
    };

    shellLocale = mkOption {
      default = {
        LC_ALL = "en_US.UTF-8";
      };
    };

    xtermFix = mkOption {
      default = true;
      description = "Will replace the TERM and TERMINAL environment variables from `xterm-` (if matched) to `xterm`";
    };

    gpgTtyFix = mkOption {
      default = true;
      description = "Will set GPG_TTY to $(tty) (or equivalent) in shell rcs";
    };

    upgradeCommands = mkOption {
      default = [];
      description = "List of commands to be put under an `upgrade` function";
    };

    elvish = {
      enable = mkOption {
        default = true;
        type = with lib.types; uniq bool;
      };

      extraMods = mkOption {
        default = [];
        description = ''
          A list of extra modules to include in $XDG_CONFIG_HOME/elvish/lib
          Each element is a set with the following keys:
            name: name of the module, can include "/". e.g, "completions/nix" would make a file
              in $XDG_CONFIG_HOME/elvish/lib/completions named nix.elv
            source: source file of the module
            enable: true if the module should be used in rc.elv, defaults to true
          Aliases are created after modules are loaded
        '';
      };

      extraFunctions = mkOption {
        default = [];
        description = ''
          A list of extra functions to include in elvish/rc.elv . The functions will be placed after
          any use statements for `my.shell.elvish.extraMods` and after aliases. Each element is a set:
          { name, arguments, body }. Arguments is optional, but if present will be put between || automatically.
          Nothing will be quoted.

          The set may also contain a 'docs' attribute to change what is rendered in the <host>-elvish.7 man page
        '';
      };

      extraCompletions = mkOption {
        default = [];
        description = ''
          A list of extra completions to include. Each completion is a string.
          Every item gets converted into elvish verbatim, before extraConfig
        '';
      };

      extraConfig = mkOption {
        default = "";
        description = "Newline delimited string that will be inserted verbatim at the end of rc.elv";
      };

      conda = {
        enable = mkOption {default = true;};
        condaCmd = mkOption {default = "conda";};
        condaRoot = mkOption {default = "${config.xdg.stateHome}/conda";};
      };

      fastForwardHook = mkOption {
        default = true;
        description = "enable edit:before-readline hook that updates the command history";
      };
    };
  };

  config = {
    home.packages = with pkgs; [stty];

    programs.starship = {
      enable = true;
      settings = {
        "$schema" = "https://starship.rs/config-schema.json";
        add_newline = true;
        shell.disabled = false;
      };
    };

    my = {
      docs.pages.shell = let
        inherit (config.my.lib) mergeTagged;
      in {
        _docsName = "Common shell aliases and functions";
        _docsExtraSections = {
          Aliases = mergeTagged (builtins.map ({
              name,
              command,
              docs ? "",
              ...
            }: {
              tag = name;
              content =
                if docs == ""
                then command
                else docs;
            })
            (builtins.filter ({docs ? "", ...}: builtins.isString docs) cfg.aliases));
        };
        _docsSeeAlso =
          optional cfg.elvish.enable
          {
            name = config.my.docs.prefix + "-elvish";
            mansection = 7;
          };
      };

      shell = {
        aliases = [
          {
            name = "sy";
            command = "sudo systemctl";
            completer = "systemctl";
          }
          {
            name = "sys";
            command = "systemctl";
            completer = "systemctl";
            external = true;
          }
          {
            name = "sysu";
            command = "systemctl --user";
            completer = "systemctl";
            external = true;
          }

          {
            name = "e";
            command = config.home.sessionVariables.EDITOR;
            completer = "$E:EDITOR";
          }
          {
            name = "E";
            command = "sudo ${config.home.sessionVariables.EDITOR}";
            completer = "$E:EDITOR";
          }

          {
            name = "xz";
            command = "xz --threads=0";
            external = true;
          }

          {
            name = "rfcdate";
            command = "date --iso-8601=seconds";
            external = true;
          }
          {
            name = "emdate";
            command = "date -R";
            external = true;
          }
          {
            name = "diff";
            command = "diff --color=auto";
            external = true;
            docs = false;
          }

          {
            name = "ls";
            command = "ls --color=auto -F -H -h";
            external = true;
            docs = false;
          }
          {
            name = "ll";
            command = "ls --color=auto -l -F -H -h";
            external = true;
          }
          {
            name = "la";
            command = "ls --color=auto -A -F -H -h";
            external = true;
          }

          {
            name = "mkd";
            command = "mkdir -pv";
            external = true;
            completer = "mkdir";
          }
          {
            name = "cp";
            command = "cp -iv";
            external = true;
            docs = false;
          }
          {
            name = "df";
            command = "df -h";
            external = true;
            docs = false;
          }
          {
            name = "du";
            command = "du -h";
            external = true;
            docs = false;
          }
          {
            name = "mv";
            command = "mv -iv";
            external = true;
            docs = false;
          }
        ];

        neededDirs = [config.home.sessionVariables.CREDENTIALS_DIRECTORY];

        elvish = {
          extraCompletions = [
            "e:nh completions --shell elvish | eval (slurp)"
          ];

          extraFunctions = [
            {
              name = "fzfd";
              arguments = "@query";
              body =
                /*
                elvish
                */
                ''
                  var q = ""
                  if (> (count $query) 0) {
                    set q = (e:fzf --walker dir,follow -q $query[0])
                  } else {
                    set q = (e:fzf --walker dir,follow)
                  }

                  if (!=s "" $q) {
                    cd $q
                  }
                '';
            }
            {
              name = "fzfdh";
              arguments = "@query";
              body =
                /*
                elvish
                */
                ''
                  var q = ""
                  if (> (count $query) 0) {
                    set q = (e:fzf --walker dir,follow,hidden -q $query[0])
                  } else {
                    set q = (e:fzf --walker dir,follow,hidden)
                  }

                  if (!=s "" $q) {
                    cd $q
                  }
                '';
            }
            {
              name = "fzfe";
              arguments = "@query";
              body =
                /*
                elvish
                */
                ''
                  var q = ""
                  if (> (count $query) 0) {
                    set q = (e:fzf -q $query[0])
                  } else {
                    set q = (e:fzf)
                  }

                  if (!=s "" $q) {
                    (external $E:EDITOR) $q
                  }
                '';
            }
          ];
        };
      };
    };
  };
}
