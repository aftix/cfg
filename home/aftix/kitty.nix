{upkgs, ...}: {
  home.packages = with upkgs; [kitty kitty-img kitty-themes];

  programs.kitty = {
    enable = true;

    font = {
      name = "Inconsolata";
      size = 18;
    };

    settings = {
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";

      kitty_mod = "ctrl+shift";
      shell = "${upkgs.elvish}/bin/elvish";
      allow_remote_control = true;

      cursor_shape = "block";
      cursor_blink_interval = -1;

      scrollback_lines = 1024;
      scrollback_pager = "'${upkgs.moar}/bin/moar' -no-linenumbers";
      scrollback_pager_history_size = 0;

      url_style = "curly";
      open_url_with = "default";
      url_prefixes = "http https file ftp";
      open_url_modifiers = "kitty_mod";

      copy_on_select = false;
      strip_trailing_spaces = "smart";
      rectangle_select_modifiers = "ctrl+shift";
      terminal_select_modifiers = "shift";
      select_by_word_characters = "@-./_~?&=%+#";
      enabled_layouts = "*";

      remember_window_size = true;
      initial_window_width = 640;
      initial_window_height = 400;

      tab_bar_edge = "top";
      tab_bar_style = "powerline";
      tab_title_template = "{title}";
      active_tab_title_template = "[{title}]";

      click_interval = -1;
      focus_follows_mouse = false;
      enable_audio_bell = false;

      background_opacity = "0.75";
      background_image = "none";
      dynamic_background_opacity = true;
    };

    keybindings = {
      "kitty_mod+c" = "copy_to_clipboard";
      "kitty_mod+v" = "paste_from_clipboard";

      "kitty_mod+up" = "scroll_line_up";
      "kitty_mod+down" = "scroll_line_down";
      "kitty_mod+page_up" = "scroll_page_up";
      "kitty_mod+page_down" = "scroll_page_down";
      "kitty_mod+home" = "scroll_home";
      "kitty_mod+end" = "scroll_end";
      "kitty_mod+h" = "show_scrollback";

      "kitty_mod+plus" = "change_font_size all +2.0";
      "kitty_mod+minus" = "change_font_size all -2.0";
      "kitty_mod+backspace" = "change_font_size all 0";

      "kitty_mod+e" = "kitten hints";
      "kitty_mod+p>f" = "kitten hints --type path --program -";
      "kitty_mod+p>shift+f" = "kitten hints --type path";
      "kitty_mod+p>l" = "kitten hints --type line --program -";
      "kitty_mod+p>w" = "kitten hints --type word --program -";
      "kitty_mod+p>h" = "kitten hints --type hash --program -";
      "kitty_mod+p>n" = "kitten hints --type linenum";

      "kitty_mod+slash" = "new_window '${upkgs.moar}/bin/moar' -no-linenumbers $HOME/.config/kitty/kitty.conf";

      "kitty_mod+enter" = "new_window";
      "ctrl+alt+enter" = "launch --cwd=current";
      "kitty_mod+w" = "close_window";
      "kitty_mod+]" = "next_window";
      "kitty_mod+[" = "previous_window";
      "kitty_mod+f" = "move_window_forward";
      "kitty_mod+b" = "move_window_backward";
      "kitty_mod+`" = "move_window_top";
      "kitty_mod+r" = "start_resizing_wondow";
      "kitty_mod+1" = "first_window";
      "kitty_mod+2" = "second_window";
      "kitty_mod+3" = "third_window";
      "kitty_mod+4" = "fourth_window";
      "kitty_mod+5" = "fifth_window";
      "kitty_mod+6" = "sixth_window";
      "kitty_mod+7" = "seventh_window";
      "kitty_mod+8" = "eighth_window";
      "kitty_mod+9" = "ninth_window";
      "kitty_mod+0" = "tenth_window";

      "kitty_mod+right" = "next_tab";
      "kitty_mod+left" = "previous_tab";
      "kitty_mod+t" = "new_tab";
      "kitty_mod+n" = "new_tab !neighbor";
      "kitty_mod+q" = "close_tab";
      "kitty_mod+." = "move_tab_forward";
      "kitty_mod+," = "move_tab_backward";
      "kitty_mod+alt+t" = "set_tab_title";

      "ctrl+alt+`" = "goto_tab -1";
      "ctrl+alt+1" = "goto_tab 1";
      "ctrl+alt+2" = "goto_tab 2";
      "ctrl+alt+3" = "goto_tab 3";
      "ctrl+alt+4" = "goto_tab 4";
      "ctrl+alt+5" = "goto_tab 5";
      "ctrl+alt+6" = "goto_tab 6";
      "ctrl+alt+7" = "goto_tab 7";
      "ctrl+alt+8" = "goto_tab 8";
      "ctrl+alt+9" = "goto_tab 9";
      "ctrl+alt+0" = "goto_tab 10";

      "kitty_mod+l" = "next_layout";
      "ctrl+alt+t" = "goto_layout tall";
      "ctrl+alt+s" = "goto_layout stack";
      "ctrl+alt+p" = "goto_layout last_used_layout";

      "kitty_mod+a>m" = "set_background_opacity +0.1";
      "kitty_mod+a>l" = "set_background_opacity -0.1";
      "kitty_mod+a>1" = "set_background_opacity 1";
      "kitty_mod+a>2" = "set_background_opacity 0.75";
      "kitty_mod+a>3" = "set_background_opacity 0.5";
      "kitty_mod+a>4" = "set_background_opacity 0.25";
      "kitty_mod+a>d" = "set_background_opacity default";
    };

    extraConfig = ''
      background            #000000
      foreground            #ffffff
      cursor                #bbbbbb
      selection_background  #b5d5ff
      color0                #000000
      color8                #545454
      color1                #ff5555
      color9                #ff5555
      color2                #55ff55
      color10               #55ff55
      color3                #ffff55
      color11               #ffff55
      color4                #5555ff
      color12               #5555ff
      color5                #ff55ff
      color13               #ff55ff
      color6                #55ffff
      color14               #55ffff
      color7                #bbbbbb
      color15               #ffffff
      selection_foreground #000000
    '';
  };

  # Extra configuration files for kitty
  xdg.configFile."kitty/open-actions.conf".text = ''
    protocol file
    fragment_matches [0-9]+
    action launch --type=overlay --cwd=current "$EDITOR" "+$FRAGMENT" "$FILE_PATH"

    protocol file
    mime text/*
    action launch --type=overlay --cwd=current "$EDITOR" "$FILE_PATH"

    protocol file
    ext rs
    action launch --type=overlay --cwd=current "$EDITOR" "$FILE_PATH"

    protocol file
    mime image/*
    action launch --type=overlay kitty +kitten icat --hold "$FILE_PATH"
  '';

  xdg.configFile."kitty/diff.conf".text = ''
    pygments_style monokai

    foreground #EDDFAA
    background #252322

    title_fg #EDDFAA
    title_bg #2D2A28

    margin_fg #48403A
    margin_bg #2D2A28

    removed_bg #23090A
    highlight_removed_bg #EB5864
    removed_margin_bg #37080B

    added_bg #164113
    highlight_added_bg #16670B
    added_margin_bg #16670B

    hunk_margin_bg #FEC14E
    hunk_bg #FEC14E

    search_bg #FEC14E
    search_fg black
    search_bg #6F96FF
    select_fg #252322
  '';
}
