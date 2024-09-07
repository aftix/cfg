{pkgs, ...}: let
  better-git-branch = final:
    final.writeShellApplication {
      name = "better-git-branch";
      runtimeInputs = with final; [git];
      text = ''
        # Taken from https://gist.github.com/schacon/e9e743dee2e92db9a464619b99e94eff
        # Colors
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        NO_COLOR='\033[0m'
        BLUE='\033[0;34m'
        YELLOW='\033[0;33m'
        NO_COLOR='\033[0m'

        width1=5
        width2=6
        width3=30
        width4=20
        width5=40

        # Function to count commits
        count_commits() {
            local branch="$1"
            local base_branch="$2"
            local ahead_behind

            ahead_behind=$(git rev-list --left-right --count "$base_branch"..."$branch")
            echo "$ahead_behind"
        }

        # Main script
        main_branch=$(git rev-parse HEAD)

        printf "''${GREEN}%-''${width1}s ''${RED}%-''${width2}s ''${BLUE}%-''${width3}s ''${YELLOW}%-''${width4}s ''${NO_COLOR}%-''${width5}s\n" "Ahead" "Behind" "Branch" "Last Commit"  " "

        # Separator line for clarity
        printf "''${GREEN}%-''${width1}s ''${RED}%-''${width2}s ''${BLUE}%-''${width3}s ''${YELLOW}%-''${width4}s ''${NO_COLOR}%-''${width5}s\n" "-----" "------" "------------------------------" "-------------------" " "


        format_string="%(objectname:short)@%(refname:short)@%(committerdate:relative)"
        IFS=$'\n'

        for branchdata in $(git for-each-ref --sort=-authordate --format="$format_string" refs/heads/ --no-merged); do
            sha=$(echo "$branchdata" | cut -d '@' -f1)
            branch=$(echo "$branchdata" | cut -d '@' -f2)
            time=$(echo "$branchdata" | cut -d '@' -f3)
            if [ "$branch" != "$main_branch" ]; then
                    # Get branch description
                    description=$(git config branch."$branch".description)

                    # Count commits ahead and behind
                    ahead_behind=$(count_commits "$sha" "$main_branch")
                    ahead=$(echo "$ahead_behind" | cut -f2)
                    behind=$(echo "$ahead_behind" | cut -f1)

                    # Display branch info
        	    printf "''${GREEN}%-''${width1}s ''${RED}%-''${width2}s ''${BLUE}%-''${width3}s ''${YELLOW}%-''${width4}s ''${NO_COLOR}%-''${width5}s\n" "$ahead" "$behind" "$branch" "$time" "$description"
            fi
        done
      '';
    };
in {
  nixpkgs.overlays = [
    (final: _: {
      better-git-branch = better-git-branch final;
    })
  ];

  home.packages = with pkgs; [pre-commit pkgs.better-git-branch];

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
          bb = "!${pkgs.better-git-branch}/bin/better-git-branch";
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
