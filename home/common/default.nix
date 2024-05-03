{
  lib,
  config,
  upkgs,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib) mkDefault;
  inherit (config.xdg) configHome dataHome stateHome;
in {
  imports = [
    ./documentation.nix
    ./elvish.nix
    ./gnupg.nix
    ./python.nix
    ./tldr.nix
    ./xdg.nix
  ];

  options.my = {
    registerMimes = mkOption {default = true;};

    shell = {
      aliases = mkOption {
        default = [];
        description = ''
          List of aliases, each alias being a set of {name, command}
          Can also contain an optional key 'completer' which is used for elvish to set the arg-completer
          ('completer' will not be quoted)
          Can also contain an optional key 'external' which will prepend the command with e: in elvish
        '';
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
        enable = mkOption {default = true;};
        development = mkOption {
          default = false;
          description = "enable development aliases in rc.elv";
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
  };

  config = {
    home = {
      language.base = mkDefault "en_US";

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

      sessionVariables = {
        FZF_DEFAULT_OPTS = mkDefault "--layout=reverse --height 40%";
        LESSHISTFILE = mkDefault "-";
        HISTFILE = mkDefault "${stateHome}/bash/history";
        PAGER = mkDefault "${upkgs.coreutils}/bin/less";
        MANPAGER = mkDefault "${upkgs.coreutils}/bin/less";
        CREDENTIALS_DIRECTORY = mkDefault "${dataHome}/systemd-creds";
        ZDOTDIR = mkDefault "${configHome}/zsh";
      };

      sessionPath = [
        "${configHome}/bin"
        "${stateHome}/nix/profiles/home-manager/home-path/bin"
      ];
    };

    my.shell = {
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
          name = "ls";
          command = "ls --color=auto -F -H -h";
          external = true;
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
        }
        {
          name = "df";
          command = "df -h";
          external = true;
        }
        {
          name = "du";
          command = "du -h";
          external = true;
        }
        {
          name = "mv";
          command = "mv -iv";
          external = true;
        }
        {
          name = "diff";
          command = "diff --color=auto";
          external = true;
        }
      ];
      neededDirs = [config.home.sessionVariables.CREDENTIALS_DIRECTORY];

      elvish.extraFunctions = [
        {
          name = "fzfd";
          arguments = "@query";
          body = ''
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
          body = ''
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
          body = ''
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

    programs = {
      home-manager.enable = true;
      starship = {
        enable = true;
        settings = {
          "$schema" = "https://starship.rs/config-schema.json";
          add_newline = true;
          shell.disabled = false;
        };
      };
    };

    services.ssh-agent.enable = upkgs.system == "x86_64-linux";

    systemd.user = {
      startServices = true;
    };
  };
}
