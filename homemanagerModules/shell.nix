# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  lib,
  pkgs,
  ...
}: let
  inherit (lib.options) mkOption;
in {
  options.aftix.shell = {
    aliases = mkOption {
      default = [];
      description = ''
        List of aliases, each alias being a set of {name, command}

        Can also contain an optional key 'external' which will prepend the command with ^ in nushell
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
  };
}
