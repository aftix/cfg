{pkgs, ...}: {
  home.packages = with pkgs; [pre-commit];

  my.shell.aliases = [
    {
      name = "g";
      command = "${pkgs.git}/bin/git";
      completer = "git";
    }
  ];

  programs = {
    git = {
      enable = true;
      extraConfig = {
        user = {
          name = "aftix";
          email = "aftix@aftix.xyz";
          signingkey = "C6F4434A6A4C3A74DC9569C247DB00554BA8E05F";
          gpgsign = true;
        };
        gpg.program = "${pkgs.gnupg}/bin/gpg2";
        commit.gpgsign = false;
        pull.rebase = false;
        init.defaultBranch = "master";
        diff = {
          tool = "kitty";
          guitool = "kitty-gui";
        };
        difftool = {
          prompt = false;
          trustExitCode = true;
        };
        difftool.kitty.cmd = "${pkgs.kitty}/bin/kitty +kitten diff $LOCAL $REMOTE";
        difftool.kitty-gui = "${pkgs.kitty}/bin/kitty kitty +kitten diff $LOCAL $REMOTE";
        rerere.enabled = true;
        column.ui = "auto";
        branch.sort = "-committerdate";
        rebase.updateRefs = true;
        alias = {
          bl = "blame -w -C -C -C";
          staash = "stash --all";
          wdiff = "diff --word-diff";
          fpush = "push --force-with-lease";
          logo = "log --oneline";
        };
      };
    };

    jujutsu = {
      enable = true;
      settings = {
        aliases.ss = ["show" "--stat"];
        backend = "gpg";
        user = {
          name = "aftix";
          email = "aftix@aftix.xyz";
        };
        ui = {
          pager = "moar -quit-if-one-screen";
          diff.tool = ["kitty" "+kitten" "diff" "$left" "$right"];
          diff-editor = ":builtin";
          default-command = "log";
        };
        colors = let
          yellow = "#ffff00";
          red = "#ff0000";
          blue = "#0000ff";
          magenta = "#ff00ff";
          cyan = "#00ffff";
          green = "#00ff00";

          bright_red = "#ee4b2b";
          bright_blue = "#0096ff";
          bright_magenta = "#ff00cd";
          bright_cyan = "#09d0ef";
          bright_green = "#aaff00";
          bright_black = "#222024";
        in {
          error = {
            fg = "default";
            bold = true;
          };
          error_source = {fg = "default";};
          warning = {
            fg = "default";
            bold = true;
          };
          hint = {fg = "default";};
          "error heading" = {
            fg = red;
            bold = true;
          };
          "error_source heading" = {bold = true;};
          "warning heading" = {
            fg = yellow;
            bold = true;
          };
          "hint heading" = {
            fg = cyan;
            bold = true;
          };

          conflict_description = yellow;
          "conflict_description difficult" = red;

          commit_id = blue;
          change_id = magenta;

          # Unique prefixes and the rest for change & commit ids;
          prefix = {bold = true;};
          rest = bright_black;
          "divergent rest" = red;
          "divergent prefix" = {
            fg = red;
            underline = true;
          };
          "hidden prefix" = "default";

          email = yellow;
          username = yellow;
          timestamp = cyan;
          working_copies = green;
          branch = magenta;
          branches = magenta;
          local_branches = magenta;
          remote_branches = magenta;
          tags = magenta;
          git_refs = green;
          git_head = green;
          divergent = red;
          "divergent change_id" = red;
          conflict = red;
          empty = green;
          placeholder = red;
          "description placeholder" = yellow;
          "empty description placeholder" = green;
          "separator" = bright_black;
          "elided" = bright_black;
          "root" = green;

          working_copy = {bold = true;};
          "working_copy commit_id" = bright_blue;
          "working_copy change_id" = bright_magenta;
          # We do not use bright yellow because of how it looks on xterm's default theme.;
          # https://github.com/martinvonz/jj/issues/528;
          "working_copy email" = yellow;
          "working_copy timestamp" = bright_cyan;
          "working_copy working_copies" = bright_green;
          "working_copy branch" = bright_magenta;
          "working_copy branches" = bright_magenta;
          "working_copy local_branches" = bright_magenta;
          "working_copy remote_branches" = bright_magenta;
          "working_copy tags" = bright_magenta;
          "working_copy git_refs" = bright_green;
          "working_copy divergent" = bright_red;
          "working_copy divergent change_id" = bright_red;
          "working_copy conflict" = bright_red;
          "working_copy empty" = bright_green;
          "working_copy placeholder" = bright_red;
          "working_copy description placeholder" = yellow;
          "working_copy empty description placeholder" = bright_green;

          "config_list name" = green;
          "config_list value" = yellow;
          "config_list overridden" = bright_black;
          "config_list overridden name" = bright_black;
          "config_list overridden value" = bright_black;

          "diff header" = yellow;
          "diff empty" = cyan;
          "diff binary" = cyan;
          "diff file_header" = {bold = true;};
          "diff hunk_header" = cyan;
          "diff removed" = red;
          "diff added" = green;
          "diff modified" = cyan;

          "op_log id" = blue;
          "op_log user" = yellow;
          "op_log time" = cyan;
          "op_log current_operation" = {bold = true;};
          "op_log current_operation id" = bright_blue;
          "op_log current_operation user" = yellow; # No bright yellow see comment above
          "op_log current_operation time" = bright_cyan;

          "node elided" = {fg = bright_black;};
          "node working_copy" = {
            fg = green;
            bold = true;
          };
          "node current_operation" = {
            fg = green;
            bold = true;
          };
          "node immutable" = {
            fg = bright_cyan;
            bold = true;
          };
          "node conflict" = {
            fg = red;
            bold = true;
          };
        };
        signing = {
          sign-all = true;
          key = "C6F4434A6A4C3A74DC9569C247DB00554BA8E05F";
          backends.gpg.allow-expired-keys = false;
        };
        git.auto-local-branch = true;
        revsets.log = "..";
      };
    };
  };
}
