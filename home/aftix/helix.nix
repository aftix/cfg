_: {
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
}
