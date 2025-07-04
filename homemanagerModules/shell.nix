# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.lists) optional;
  inherit (lib.options) mkOption;
  cfg = config.aftix.shell;
in {
  options.aftix.shell = {
    aliases = mkOption {
      default = [];
      description = ''
        List of aliases, each alias being a set of {name, command}

        Can also contain an optional key 'external' which will prepend the command with ^ in nushell

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
      default = false;
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

    nushell = {
      enable = mkOption {
        default = true;
        type = with lib.types; uniq bool;
      };

      plugins = mkOption {
        default =
          (with pkgs.nushellPlugins; [query gstat polars formats skim])
          ++ (with pkgs; [
            nu_plugin_audio_hook
            nu_plugin_compress
            nu_plugin_desktop_notifications
            nu_plugin_dns
            nu_plugin_explore
            nu_plugin_semver
            nu_plugin_strutils
          ]);
        description = "list of nushell plugin packages to install";
        type = with lib.types; listOf package;
      };

      extraMods = mkOption {
        default = [];
        description = ''
          A list of extra modules to include in $XDG_CONFIG_HOME/nushell
          Each element is a set with the following keys:
            name: name of the module, can include "/". e.g, "completions/nix" would make a file
              in $XDG_CONFIG_HOME/nushell/completions named nix.elv
            source: source file of the module
            enable: true if the module should be used in config.nu, defaults to true
          Aliases are created after modules are loaded
        '';
      };

      extraCommands = mkOption {
        default = [];
        description = ''
          A list of extra commands to include in nushell/config.nu. The functions will be placed after
          any use statements for `aftix.shell.nushell.extraMods` and after aliases. Each element is a set:
          { name, arguments, body }. Arguments is optional, but if present will be put between [] automatically.
          Nothing will be quoted.

          The set may also contain a 'docs' attribute to change what is rendered in the <host>-nushell.7 man page

          The set may also contain an 'init' attribute which is a string to be inserted after the `use` statement
          The set may also contain an 'extra' attribute which is a string to be insterted at the end of the `use` statement (i.e. "*")
        '';
      };

      extraConfig = mkOption {
        default = "";
        description = "Newline delimited string that will be inserted verbatim at the end of config.nu";
      };
    };
  };

  config = {
    home.packages = with pkgs; [coreutils-full];

    programs = {
      carapace.enable = true;

      starship = {
        enable = true;
        settings = {
          "$schema" = "https://starship.rs/config-schema.json";
          add_newline = true;
          shell.disabled = false;
        };
      };
    };

    aftix = {
      docs.pages.shell = let
        inherit (pkgs.aftixLib) mergeTagged;
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
          optional cfg.nushell.enable
          {
            name = config.aftix.docs.prefix + "-nushell";
            mansection = 7;
          };
      };

      shell = {
        aliases = [
          {
            name = "sy";
            command = "sudo systemctl";
          }
          {
            name = "sys";
            command = "systemctl";
            external = true;
          }
          {
            name = "sysu";
            command = "systemctl --user";
            external = true;
          }

          {
            name = "e";
            command = config.home.sessionVariables.EDITOR;
          }
          {
            name = "E";
            command = "sudo ${config.home.sessionVariables.EDITOR}";
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
            name = "dfx";
            command = "df -x tmpfs -x fuse -h";
            external = true;
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
      };
    };
  };
}
