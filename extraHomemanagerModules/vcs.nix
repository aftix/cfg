# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  pkgs,
  lib,
  config,
  ...
}: let
  allowedSigners = pkgs.writeTextFile {
    name = "allowed-signers";
    text = ''
      ${config.aftix.statics.primarySSHPubkey}
    '';
  };

  better-git-branch = pkgs.writeShellApplication {
    name = "better-git-branch";
    runtimeInputs = with pkgs; [git];
    text = ''
      set +o errexit
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
  home.packages = [pkgs.pre-commit better-git-branch pkgs.delta];

  aftix.shell.aliases = [
    {
      name = "g";
      command = lib.getExe pkgs.git;
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
          signingKey = "${config.home.homeDirectory}/.ssh/id_ed25519_sk";
          gpgsign = true;
        };

        gpg.format = "ssh";

        core = {
          untrackedcache = true;
          fsmonitor = true;
          pager = lib.getExe pkgs.delta;
        };

        pager.blame = lib.getExe pkgs.delta;
        interactive.diffFilter = "${lib.getExe pkgs.delta} --color-only";
        delta = {
          navigate = true;
          side-by-side = true;
          line-numbers = true;
          hyperlinks = true;
          width = "-4";
        };
        merge.conflictstyle = "zdiff3";

        commit.gpgsign = false;
        pull.rebase = false;
        init.defaultBranch = "master";

        diff = {
          colorMoved = "default";
          guitool = "kitty-gui";
        };
        difftool = {
          prompt = false;
          trustExitCode = true;
        };
        difftool.kitty-gui = "${lib.getExe pkgs.kitty} +kitten diff $LOCAL $REMOTE";

        rerere.enabled = true;
        column.ui = "auto";
        branch.sort = "-committerdate";
        rebase.updateRefs = true;

        alias = {
          bb = "!${lib.getExe better-git-branch}";
          bl = "blame -w -C -C -C";
          staash = "stash --all";
          wdiff = "diff --word-diff";
          fpush = "push --force-with-lease";
          logo = "log --oneline";
        };

        fetch.writeCommitGraph = true;
      };
    };

    jujutsu = {
      enable = true;
      settings = {
        aliases = {
          credit = ["file" "annotate"];
          s = ["show"];
          ss = ["show" "--stat"];
          nt = ["new" "trunk()"];
          llog = ["log" "-T" "builtin_log_detailed"];
          logall = ["log" "-r" ".."];
          llogall = ["log" "-r" ".." "-T" "builtin_log_detailed"];

          open = ["log" "-r" "open()"];
          open-tree = ["log" "-r" "open_tree()"];
          ready = ["log" "-r" "ready()"];
          ready-tree = ["log" "-r" "ready_tree()"];
          retrunk = ["rebase" "--destination" "trunk()"];
          retrunk-stack = ["rebase" "--destination" "trunk()" "-s" "all:roots(trunk()..stack(@))"];
          retrunk-open = ["rebase" "--destination" "trunk()" "-s" "all:roots(trunk()..open())"];
          retrunk-ready = ["rebase" "--destination" "trunk()" "-s" "all:roots(trunk()..ready())"];
          megamerge = ["log" "-r" "megamerge_fork_point()::@"];
          megamerge-tree = ["log" "-r" "megamerge_fork_point()::"];
          megamerge-add = ["rebase" "-B" "megamerge()" "-A" "megamerge_fork_point()" "-r"];
          megamerge-remove = ["util" "exec" "--" "sh" "-lc" "jj rebase -s 'megamerge()' --destination \"all:megamerge()- ~ $1\"" "none"];
          consume = ["squash" "--into" "@" "--from"];
          eject = ["squash" "--from" "@" "--into"];
          tug = ["bookmark" "move" "--from" "closest_bookmarked_ancestor()" "--to" "heads_nonempty()"];
        };

        user = {
          name = "aftix";
          email = "aftix@aftix.xyz";
        };

        "--scope" = [
          {
            "--when".commands = ["diff" "show"];
            ui = {
              pager = "${lib.getExe pkgs.delta} --file-transformation 's|.*/jj-diff-[^/]*/[^/]*/||'";
              diff.format = "git";
            };
          }
        ];

        ui = {
          pager = "${lib.getExe pkgs.moar} -quit-if-one-screen";
          diff-editor = ":builtin";
          default-command = "log";
          movement.edit = true;
        };

        merge.tools.delta.diff-expected-exit-codes = [0 1];

        colors = let
          yellow = "#ffff00";
          red = "#ff0000";
          blue = "#0000ff";
          magenta = "#ff00ff";
          cyan = "#00ffff";
          green = "#00ff00";

          bright_yellow = "#ffed29";
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
          "working_copy email" = bright_yellow;
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
          behavior = "drop";
          backend = "ssh";
          key = "${config.home.homeDirectory}/.ssh/id_ed25519_sk";
        };
        backends.ssh.allowed-signers = "${allowedSigners}";

        git = {
          auto-local-bookmark = true;
          colocate = true;
          push-bookmark-prefix = "aftix/push-";
          private-commits = "local_only()";
          sign-on-push = true;
        };

        snapshot.auto-update-stale = true;

        revsets = {
          log = "stack()";
          log-graph-prioritize = "coalesce(megamerge(), trunk())";
        };

        revset-aliases = {
          "user(x)" = "author(x) | committer(x)";

          "immutable_heads()" = "present(trunk()) | (remote_bookmarks() ~ pushes() ~ ghstack()) | tags()";
          "pushes()" = "remote_bookmarks(glob:\"aftix/push-*\")";
          "gh_pages()" = "ancestors(remote_bookmarks(exact:\"gh-pages\"))";
          "ghstack()" = "remote_bookmarks(glob:\"gh/aftix/*/orig\")";
          "trunk()" = "latest((present(main) | present(master)) & remote_bookmarks())";

          "wip()" = "description(glob:\"wip:*\")";
          "private()" = "description(glob:\"private:*\")";
          "local_only()" = "wip() | private()";

          "stack()" = "ancestors(reachable(@, mutable()), 2)";
          "stack(x)" = "ancestors(reachable(x, mutable()), 2)";
          "stack(x, n)" = "ancestors(reachable(x, mutable()), n)";

          "open()" = "stack(trunk().. & mine(), 1)";
          "open_tree()" = "fork_point(ancestors(open()) & mutable())::";
          "ready()" = "open() ~ local_only()::";
          "ready_tree()" = "fork_point(ancestors(ready()) & mutable())::";

          "megamerge()" = "heads(::reachable(stack(), merges()))";
          "megamerge(x)" = "heads(::reachable(stack(x), merges()))";
          "megamerge_fork_point()" = "fork_point(megamerge()-)";
          "megamerge_fork_point(x)" = "fork_point(megamerge(x)-)";

          "closest_bookmarked_ancestor()" = "heads(::@- & bookmarks())";
          "closest_bookmarked_ancestor(x)" = "heads(::x- & bookmarks())";

          "heads_nonempty()" = "heads(::@ ~ empty())";
          "heads_nonempty(x)" = "heads(::x ~ empty())";
        };

        templates = {
          commit_trailers = ''
            if(!trailers.contains_key("Change-Id") && config("gerrit.enable").as_boolean(), format_gerrit_change_id_trailer(self))
          '';
        };

        # Must be set globally to a default value so the config() template function doesn't panic
        gerrit.enable = false;
      };
    };
  };
}
