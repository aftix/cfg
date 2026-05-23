# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkOverride;
  inherit (lib.lists) optionals;

  devCfg =
    {
      nix = true;
      rust = true;
      go = true;
      cpp = true;
      typescript = true;
      gh = true;
      steel = true;

      nixdConfig = {};
    }
    // (config.aftix.development or {});
in {
  home = {
    packages = with pkgs;
      [
        markdown-oxide
        bash-language-server
      ]
      ++ (optionals devCfg.typescript [typescript-language-server])
      ++ (optionals config.aftix.shell.nushell.enable [nufmt])
      ++ (optionals devCfg.nix [nixd alejandra])
      ++ (optionals devCfg.go [gopls]);

    sessionVariables = {
      EDITOR = mkOverride 900 "${lib.getExe pkgs.helix}";
      VISUAL = mkOverride 900 "${lib.getExe pkgs.helix}";
    };
  };

  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = {
      theme = "stylix";

      keys.normal = {
        g = {
          a = "code_action";
          q = ":reflow";
        };
      };

      editor = {
        line-number = "relative";
        auto-completion = true;
        auto-info = true;
        completion-trigger-len = 2;
        true-color = true;
        shell = ["zsh" "-cl"];
        bufferline = "multiple";

        whitespace = {
          render = "all";
          characters = {
            space = " ";
            nbsp = "⍽";
            tab = "→";
            newline = "¬";
            tabpad = ".";
          };
        };

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        file-picker = {
          hidden = false;
          git-global = true;
          git-ignore = true;
          parents = true;
        };

        lsp = {
          display-messages = true;
          display-inlay-hints = true;
        };
        inline-diagnostics.cursor-line = "warning";

        search = {
          smart-case = true;
          wrap-around = false;
        };

        indent-guides = {
          render = true;
          character = "|";
        };
      };
    };

    languages = lib.mkMerge [
      (lib.mkIf (devCfg.nixdConfig != {}) {
        language-server.nixd.config = devCfg.nixdConfig;
      })
      (lib.mkIf devCfg.nix {
        language = [
          {
            name = "nix";
            auto-format = true;
            formatter = {
              command = lib.getExe pkgs.alejandra;
            };
          }
        ];
      })
      (lib.mkIf devCfg.steel {
        language-server.steel-language-server = {
          command = lib.getExe pkgs.steel-language-server;
          args = [];
        };
        language = [
          {
            name = "steel";
            scope = "source.steel";
            file-types = ["steel"];
            injection-regex = "steel";
            auto-format = false;
            grammar = "scheme";
            comment-tokens = ";";
            language-servers = ["steel-language-server"];

            indent = {
              tab-width = 4;
              unit = "    ";
            };

            auto-pairs = {
              "(" = ")";
              "{" = "}";
              "[" = "]";
              "\"" = "\"";
            };
          }
        ];
      })
    ];
  };

  xdg.mimeApps.defaultApplications = pkgs.aftixLib.registerMimes [
    {
      application = "Helix";
      mimetypes = [
        "text/plain"
        "text/csv"
        "text/tab-separated-values"
        "text/markdown"
        "text/html"
        "text/xml"
        "text/css"
        "text/javascript"
        "text/ecmascript"
        "text/rust"
        "text/x-go"
        "text/x-c"
        "text/x-h"
        "text/x-shellscript"
        "text/x-script.csh"
        "text/x-script.ksh"
        "text/x-script.lisp"
        "text/x-script.elisp"
        "text/x-script.scheme"
        "text/x-script.perl"
        "text/x-script.python"
        "text/x-script.zsh"
        "text/x-asm"
        "text/x-fortran"
        "text/x-java-source"
        "text/x-latex"
        "text/x-m"
        "text/x-pascal"
        "application/x-httpd-php"
        "application/xhtml+xml"
        "application/atom+xml"
        "application/xml"
        "application/x-csh"
        "application/json"
      ];
    }
  ];
}
