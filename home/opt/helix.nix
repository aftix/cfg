{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkOverride;
  inherit (config.dep-inject) inputs;
in {
  home = {
    packages = with pkgs; [
      nil
      markdown-oxide
      gopls
      bash-language-server
      nodePackages_latest.typescript-language-server
    ];

    sessionVariables = {
      EDITOR = mkOverride 900 "${pkgs.helix}/bin/hx";
      VISUAL = mkOverride 900 "${pkgs.helix}/bin/hx";
    };
  };

  programs.helix = {
    enable = true;
    defaultEditor = true;
    languages = mkOverride 900 {};
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

        lsp.display-messages = true;
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
  };

  xdg = {
    configFile."helix/languages.toml".source = "${inputs.helix}/languages.toml";

    mimeApps.defaultApplications = config.my.lib.registerMimes [
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
  };
}
