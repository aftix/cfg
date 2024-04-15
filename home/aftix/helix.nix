{mylib ? {registerMimes = _: {};}, ...}: {
  # Helix installed system wide

  programs.helix = {
    enable = true;
    defaultEditor = true;
    languages = builtins.fromTOML (builtins.readFile ./_external/helix/languages.toml);
    settings = {
      theme = "ayu_dark";
      editor = {
        line-number = "relative";
        auto-completion = true;
        auto-info = true;
        completion-trigger-len = 2;
        true-color = true;
        shell = ["zsh" "-cl"];
        bufferline = "multiple";
      };
      editor.whitespace.render = "all";
      editor.whitespace.characters = {
        space = " ";
        nbsp = "⍽";
        tab = "→";
        newline = "¬";
        tabpad = ".";
      };
      editor.cursor-shape = {
        insert = "bar";
        normal = "block";
        select = "underline";
      };
      editor.file-picker = {
        hidden = false;
        git-global = true;
        git-ignore = true;
        parents = true;
      };
      editor.lsp.display-messages = true;
      editor.search.smart-case = true;
      editor.search.wrap-around = false;
      editor.indent-guides.render = true;
      editor.indent-guides.character = "|";
    };
  };

  xdg.mimeApps.defaultApplications = mylib.registerMimes [
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
