{
  mylib,
  upkgs,
  config,
  ...
}: let
  docPrefix = config.mydocs.prefix;
  binds = {
    mouse_left_click = {
      tag = "Left Click";
      content = "Close the clicked notification";
      value = "close_current";
    };
    mouse_middle_click = {
      tag = "Middle Click";
      content = "Perform Dunst action on notification";
      value = "do_action";
    };
    mouse_right_click = {
      tag = "Right Click";
      content = "Close all active notifications";
      value = "close_all";
    };
  };
in {
  mydocs.pages.dunst = with mylib.docs; {
    _docsName = "dunst \\- A customizable and lightweight notification-daemon";
    _docsExtraSections = {
      Interaction = mergeSubsections {"Mouse Controls" = mergeTaggedAttrs binds;};
    };
    _docsSeeAlso = [
      {
        name = "dunst";
        mansection = 1;
      }
      {name = docPrefix + "-hyprland";}
    ];
  };

  services.dunst = {
    enable = true;

    settings = {
      global = {
        monitor = 0;
        follow = "mouse";
        geometry = "300x5-30+20";
        indicate_hidden = true;
        shrink = false;
        transparency = 0;
        notification_height = 0;
        separator_height = 2;
        padding = 0;
        horizontal_padding = 8;
        frame_width = 3;
        frame_color = "#aaaaaa";
        separator_color = "frame";
        sort = true;
        idle_threshold = 120;
        font = "Inconsolata 8";
        line_height = 0;
        markup = "full";
        format = ''
          <b>%s</b>
          %b'';
        alignment = "left";
        show_age_threshold = 60;
        word_wrap = true;
        ellipsize = "middle";
        ignore_newline = false;
        stack_duplicates = true;
        hide_duplicate_count = false;
        show_indicators = true;
        icon_position = "left";
        max_icon_size = 32;
        sticky_history = true;
        history_lenght = 20;
        dmenu = "${upkgs.tofi}/bin/tofi -p dunst:";
        browser = "/run/current-system/sw/bin/firefox -new-tab";
        always_run_script = true;
        title = "Dunst";
        class = "Dunst";
        startup_notification = false;
        verbosity = "mesg";
        corner_radius = 0;
        mouse_left_click = "close_current";
        mouse_middle_click = "do_action";
        mouse_right_click = "close_all";
      };
      experimental.per_monitor_dpi = false;
      shortcuts = {
        close = "ctrl+space";
        close_all = "ctrl+shift+space";
        history = "ctrl+grave";
        context = "ctrl+shift+period";
      };
      urgency_low = {
        background = "#222222";
        foreground = "#888888";
        timeout = 10;
      };
      urgency_normal = {
        background = "#285577";
        foreground = "#ffffff";
        timeout = 10;
      };
      urgency_critical = {
        background = "#900000";
        foreground = "#ffffff";
        frame_color = "#ff0000";
        timeout = 0;
      };
    };
  };
}
