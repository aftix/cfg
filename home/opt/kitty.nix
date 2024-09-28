{
  pkgs,
  lib,
  config,
  ...
}: let
  settings = {
    shell = {
      tag = "shell";
      content = "elvish";
      value = config.programs.kitty.settings.shell;
    };

    scrollbackPager = {
      tag = "scrollback pager";
      content = "moar";
      value = config.programs.kitty.settings.scrollback_pager;
    };

    kittyMod = {
      tag = "kitty_mod";
      content = "ctrl + shift \\- Main modifiers used for kitty keyboard shortcuts, referenced as kitty_mod in this manual";
      value = "ctrl+shift";
    };
  };

  binds = {
    copy = {
      tag = "kitty_mod + c";
      content = "Copy selection to clipboard";
      value = "copy_to_clipboard";
    };
    paste = {
      tag = "kitty_mod + v";
      content = "Paste from clipboard";
      value = "paste_from_clipboard";
    };

    scrollUp = {
      tag = "kitty_mod + up";
      content = "Scroll up in by a line";
      value = "scroll_line_up";
    };
    scrollDown = {
      tag = "kitty_mod + down";
      content = "Scroll down in by a line";
      value = "scroll_line_down";
    };
    pageUp = {
      tag = "kitty_mod + page_up";
      content = "Scroll up in by a page";
      value = "scroll_page_up";
    };
    pageDown = {
      tag = "kitty_mod + page_down";
      content = "Scroll down in by a page";
      value = "scroll_page_down";
    };
    scrollHome = {
      tag = "kitty_mod + home";
      content = "Scroll to the beginning of the scrollback history";
      value = "scroll_home";
    };
    scrollEnd = {
      tag = "kitty_mod + end";
      content = "Scroll to the end of the scrollback history";
      value = "scroll_end";
    };
    scrollShowback = {
      tag = "kitty_mod + h";
      content = "Show the scrollback history in the pager";
      value = "show_scrollback";
    };

    increaseFontSize = {
      tag = "kitty_mod + plus";
      content = "Increase the font size by 2pt";
      value = "change_font_size all +2.0";
    };
    decreaseFontSize = {
      tag = "kitty_mod+minus";
      content = "Decrease the font size by 2pt";
      value = "change_font_size all -2.0";
    };
    resetFontSize = {
      tag = "kitty_mod + backspace";
      content = "Reset the font size to the default";
      value = "change_font_size all 0";
    };

    showConfig = {
      tag = "kitty_mod + slash";
      content = "Open the kitty configuration in the pager in a new window";
      value = "new_window '${pkgs.moar}/bin/moar' -no-linenumbers $HOME/.config/kitty/kitty.conf";
    };

    opacityMore = {
      tag = "kitty_mod + a > m";
      content = "Increase the background opacity by 10%";
      value = "set_background_opacity +0.1";
    };
    opacityLess = {
      tag = "kitty_mod + a > l";
      content = "Decrease the background opacity by 10%";
      value = "set_background_opacity -0.1";
    };
    opacityFull = {
      tag = "kitty_mod + a > 1";
      content = "Set the background opacity to 100%";
      value = "set_background_opacity 1";
    };
    opacityHigh = {
      tag = "kitty_mod + a > 2";
      content = "Set the background opacity to 75%";
      value = "set_background_opacity 0.75";
    };
    opacityMiddle = {
      tag = "kitty_mod + a > 3";
      content = "Set the background opacity to 50%";
      value = "set_background_opacity 0.5";
    };
    opacityLow = {
      tag = "kitty_mod + a > 4";
      content = "Set the background opacity to 25%";
      value = "set_background_opacity 0.25";
    };
    opacityDefault = {
      tag = "kitty_mod + a > d";
      content = "Reset the background opacity to the default";
      value = "set_background_opacity default";
    };
  };

  hintBinds = {
    kittenUrls = {
      tag = "kitty_mod + e";
      content = "Open the hint menu for opening URLs";
      value = "kitten hints";
    };
    kittenPaths = {
      tag = "kitty_mod + p > f";
      content = "Open the hint menu for paths";
      value = "kitten hints --type path --program -";
    };
    kittenPathsOpen = {
      tag = "kitty_mod + p > shift+f";
      content = "Open the hint menu for opening paths";
      value = "kitten hints --type path";
    };
    kittenLines = {
      tag = "kitty_mod + p > l";
      content = "Open the hint menu for lines";
      value = "kitten hints --type line --program -";
    };
    kittenWords = {
      tag = "kitty_mod + p > w";
      content = "Open the hint menu for words";
      value = "kitten hints --type word --program -";
    };
    kittenHash = {
      tag = "kitty_mod + p > h";
      content = "Open the hint menu for hashes";
      value = "kitten hints --type hash --program -";
    };
    kittenLinenum = {
      tag = "kitty_mod + p > n";
      content = "Open the hint menu for line numbers";
      value = "kitten hints --type linenum";
    };
  };

  windowBinds = {
    launchWindow = {
      tag = "kitty_mod + enter";
      content = "Open a new window";
      value = "new_window";
    };
    launchWindowCurrent = {
      tag = "ctrl + alt + enter";
      content = "Open a new window, preserving the current working directory";
      value = "launch --cwd=current";
    };
    closeWindow = {
      tag = "kitty_mod + w";
      content = "Close the focused window";
      value = "close_window";
    };
    nextWindow = {
      tag = "kitty_mod + ]";
      content = "Focus the next window";
      value = "next_window";
    };
    prevWindow = {
      tag = "kitty_mod + [";
      content = "Focus the previous window";
      value = "previous_window";
    };
    moveWindow = {
      tag = "kitty_mod + f";
      content = "Move the focused window forwards in the window stack";
      value = "move_window_forward";
    };
    moveWindowBack = {
      tag = "kitty_mod + b";
      content = "Move the focused window backwards in the window stack";
      value = "move_window_backward";
    };
    moveWindowTop = {
      tag = "kitty_mod + `";
      content = "Move the focused window to the top of the window stack";
      value = "move_window_top";
    };

    startResize = {
      tag = "kitty_mod + r";
      content = "Start resizing the window";
      value = "start_resizing_window";
    };
    firstWindow = {
      tag = "kitty_mod + 1";
      content = "Move to the first window";
      value = "first_window";
    };
    secondWindow = {
      tag = "kitty_mod + 2";
      content = "Move to the first window";
      value = "second_window";
    };
    thirdWindow = {
      tag = "kitty_mod + 3";
      content = "Move to the third window";
      value = "third_window";
    };
    fourthWindow = {
      tag = "kitty_mod + 4";
      content = "Move to the fourth window";
      value = "fourth_window";
    };
    fifthWindow = {
      tag = "kitty_mod + 5";
      content = "Move to the fifth window";
      value = "fifth_window";
    };
    sixthWindow = {
      tag = "kitty_mod + 6";
      content = "Move to the sixth window";
      value = "sixth_window";
    };
    seventhWindow = {
      tag = "kitty_mod + 7";
      content = "Move to the seventh window";
      value = "seventh_window";
    };
    eightWindow = {
      tag = "kitty_mod + 8";
      content = "Move to the eigth window";
      value = "eighth_window";
    };
    ninthWindow = {
      tag = "kitty_mod + 9";
      content = "Move to the nineth window";
      value = "ninth_window";
    };
    tenthWindow = {
      tag = "kitty_mod + 0";
      content = "Move to the tenth window";
      value = "tenth_window";
    };
  };

  tabBinds = {
    nextTab = {
      tag = "kitty_mod + right";
      content = "Focus the next tab";
      value = "next_tab";
    };
    prevTab = {
      tag = "kitty_mod + left";
      content = "Focus the previous tab";
      value = "previous_tab";
    };
    newTab = {
      tag = "kitty_mod + t";
      content = "Launch a new tab at the end of the tab list";
      value = "new_tab";
    };
    newTabNeighbor = {
      tag = "kitty_mod + n";
      content = "Launch a new tab and place it after the focused tab";
      value = "new_tab !neighbor";
    };
    closeTab = {
      tag = "kitty_mod + q";
      content = "Close the focused tab";
      value = "close_tab";
    };
    moveTab = {
      tag = "kitty_mod + .";
      content = "Move the focused tab forward";
      value = "move_tab_forward";
    };
    moveTabBack = {
      tag = "kitty_mod + ,";
      content = "Move the focused tab backwards";
      value = "move_tab_backward";
    };
    setTabTitle = {
      tag = "kitty_mod + alt + t";
      content = "Set the focused tab's title";
      value = "set_tab_title";
    };

    gotoTabPrev = {
      tag = "ctrl + alt + `";
      content = "Focus to the previously focused tab";
      value = "goto_tab -1";
    };
    gotoTabFirst = {
      tag = "ctrl + alt + 1";
      content = "Focus the first tab";
      value = "goto_tab 1";
    };
    gotoTabSecond = {
      tag = "ctrl + alt + 2";
      content = "Focus the second tab";
      value = "goto_tab 2";
    };
    gotoTabThird = {
      tag = "ctrl + alt + 3";
      content = "Focus the third tab";
      value = "goto_tab 3";
    };
    gotoTabFourth = {
      tag = "ctrl + alt + 4";
      content = "Focus the fourth tab";
      value = "goto_tab 4";
    };
    gotoTabFifth = {
      tag = "ctrl + alt + 5";
      content = "Focus the fifth tab";
      value = "goto_tab 5";
    };
    gotoTabSixth = {
      tag = "ctrl + alt + 6";
      content = "Focus the sixth tab";
      value = "goto_tab 6";
    };
    gotoTabSeventh = {
      tag = "ctrl + alt + 7";
      content = "Focus the seventh tab";
      value = "goto_tab 7";
    };
    gotoTabEighth = {
      tag = "ctrl + alt + 8";
      content = "Focus the eigth tab";
      value = "goto_tab 8";
    };
    gotoTabNineth = {
      tag = "ctrl + alt + 9";
      content = "Focus the ninth tab";
      value = "goto_tab 9";
    };
    gotoTabTenth = {
      tag = "ctrl + alt + 0";
      content = "Focus the tenth tab";
      value = "goto_tab 10";
    };
  };

  layoutBinds = {
    layoutNext = {
      tag = "kitty_mod + l";
      content = "Cycle the window layout forwards";
      value = "next_layout";
    };
    layoutTall = {
      tag = "ctrl + alt + t";
      content = "Use the tall window layout";
      value = "goto_layout tall";
    };
    layoutStack = {
      tag = "ctrl + alt + s";
      content = "Use the stacking window layout";
      value = "goto_layout stack";
    };
    layoutLast = {
      tag = "ctrl + alt + p";
      content = "Use the previously used layout";
      value = "goto_layout last_used_layout";
    };
  };

  mouseBinds = {
    pasteText = {
      tag = "middle click";
      content = "Paste from the primary selection";
      value = "mouse_map middle release ungrabbed paste_from_selection";
    };
    pasteUnconditional = {
      tag = "shift + middle click";
      content = "Paste from the primary selection even when grabbed";
      value = ''
        mouse_map shift+middle release ungrabbed,grabbed paste_from_selection
        mouse_map shift+middle press grabbed discard_event
      '';
    };

    startSelect = {
      tag = "left click";
      content = "Start selecting text";
      value = "mouse_map left press ungrabbed,grabbed mouse_selection normal";
    };
    startRectSelect = {
      tag = "kitty_mod + left click";
      content = "Start selecting text in a rectangle";
      value = "mouse_map kitty_mod+left press ungrabbed,grabbed mouse_selection rectangle";
    };
    selectWord = {
      tag = "double left click";
      content = "Select a word";
      value = "mouse_map left doublepress ungrabbed,grabbed mouse_selection word";
    };
    selectLine = {
      tag = "triple left click";
      content = "Select a line";
      value = "mouse_map left triplepress ungrabbed,grabbed mouse_selection line";
    };
    selectLineFromPoint = {
      tag = "kitty_mod + triple left click";
      content = "Select a line starting from the cursor position";
      value = "mouse_map kitty_mod+left triplepress ungrabbed,grabbed mouse_selection line_from_point";
    };
    extendSelection = {
      tag = "right click";
      content = "Extend the current selection";
      value = "mouse_map right press ungrabbed,grabbed mouse_selection extend";
    };

    showCmd = {
      tag = "kitty_mod + right click";
      content = "Show clicked command in pager";
      value = "mouse_map kitty_mod+right press ungrabbed mouse_show_command_output";
    };

    openUrl = {
      tag = "ctrl + left click";
      content = "Open a URL with the default MIME scheme handler";
      value = "mouse_map ctrl+left release grabbed,ungrabbed mouse_handle_click link";
    };
  };

  mkKittyBinds = attrs:
    lib.mergeAttrsList (
      lib.mapAttrsToList (_: v: let
        name = builtins.replaceStrings [" "] [""] v.tag;
      in {"${name}" = v.value;})
      attrs
    );

  inherit (config.my.lib) paragraph example mergeTaggedAttrs mergeSubsections;
in {
  home = {
    packages = with pkgs; [kitty-img kitty-themes];

    sessionVariables = rec {
      TERM = "kitty";
      TERMINAL = TERM;
    };
  };

  my.docs.pages.kitty = {
    _docsName = "kitty \\- The fast, feature rich terminal emulator";
    _docsExtraSections = {
      "Shortcut Format" = paragraph ''
        A '+' between key names indicate the keys are pressed together. A '>' indicates
        that they key combination to the left must be pressed then released, then the key combination to
        the right (possible including more '>' characters) must be pressed to activate the keyboard shortcut.
        All letters are case insensitive.

        ${
          example
          "A shortcut that is triggered by pressing control, shift, and p together"
          "ctrl + shift + p"
        }

        ${
          example
          "A shortcut that is triggered by pressing control, shift, and p together then pressing x"
          "ctrl + shift + p > x"
        }
      '';
      Miscellaneous = mergeTaggedAttrs settings;
      Interaction = mergeSubsections {
        "Keyboard Shortcuts" = builtins.concatStringsSep "\n" [
          (mergeTaggedAttrs binds)
          (
            mergeSubsections {
              "Hint selection shortcuts" = mergeTaggedAttrs hintBinds;
              "Window management shortcuts" = mergeTaggedAttrs windowBinds;
              "Tab management shortcuts" = mergeTaggedAttrs tabBinds;
              "Layout management shortcuts" = mergeTaggedAttrs layoutBinds;
            }
          )
        ];
        "Mouse Controls" = mergeTaggedAttrs mouseBinds;
      };
    };

    _docsSeeAlso = [
      {
        name = "kitty";
        mansection = 1;
      }
      {
        name = "kitty.conf";
        mansection = 5;
      }
    ];
  };

  programs.kitty = {
    enable = true;

    settings = {
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";

      kitty_mod = settings.kittyMod.value;
      shell = lib.mkDefault (
        if config.my.shell.elvish.enable
        then "${pkgs.elvish}/bin/elvish"
        else if config.my.shell.nushell.enable
        then "${pkgs.nushell}/bin/nu"
        else "${pkgs.zsh}/bin/zsh"
      );
      allow_remote_control = true;

      cursor_shape = "block";
      cursor_blink_interval = -1;

      scrollback_lines = 1024;
      scrollback_pager = lib.mkDefault "${pkgs.less}/bin/less";
      scrollback_pager_history_size = 0;

      url_style = "curly";
      open_url_with = "default";
      url_prefixes = "http https file ftp";

      copy_on_select = false;
      strip_trailing_spaces = "smart";
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

      background_image = "none";
      dynamic_background_opacity = true;
    };

    keybindings = lib.mergeAttrsList (map mkKittyBinds [
      binds
      hintBinds
      windowBinds
      tabBinds
      layoutBinds
    ]);

    extraConfig =
      "clear_all_mouse_actions yes\n"
      + builtins.concatStringsSep "\n" (lib.mapAttrsToList (_: mbind: mbind.value) mouseBinds)
      + ''

        mouse_map kitty_mod+left press grabbed discard_event
      '';
  };

  my.shell.aliases = [
    {
      name = "icat";
      command = "kitty +kitten icat";
    }
    {
      name = "kdiff";
      command = "kitty +kitten diff";
    }
    {
      name = "ssh";
      command = "kitty +kitten ssh -o \"VisualHostKey=yes\"";
    }
  ];

  # Extra configuration files for kitty
  xdg.configFile = {
    "kitty/open-actions.conf".text = ''
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

    "kitty/diff.conf".text = ''
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
  };
}
