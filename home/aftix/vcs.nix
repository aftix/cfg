{upkgs, ...}: {
  home.packages = with upkgs; [git jujutsu];

  programs.git = {
    enable = true;
    extraConfig = {
      user = {
        name = "aftix";
        email = "aftix@aftix.xyz";
        signingkey = "C6F4434A6A4C3A74DC9569C247DB00554BA8E05F";
        gpgsign = true;
      };
      gpg.program = "${upkgs.gnupg}/bin/gpg2";
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
      difftool.kitty.cmd = "${upkgs.kitty}/bin/kitty +kitten diff $LOCAL $REMOTE";
      difftool.kitty-gui = "${upkgs.kitty}/bin/kitty kitty +kitten diff $LOCAL $REMOTE";
      rerere.enabled = true;
      column.ui = "auto";
      branch.sort = "-committerdate";
      rebase.updateRefs = true;
      aliases = {
        bl = "blame -w -C -C -C";
        staash = "stash --all";
        wdiff = "diff --word-diff";
        fpush = "push --force-with-lease";
        logo = "log --oneline";
      };
    };
  };

  programs.jujutsu = {
    enable = true;
    settings = {
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
      signing = {
        sign-all = true;
        key = "C6F4434A6A4C3A74DC9569C247DB00554BA8E05F";
        backends.gpg.allow-expired-keys = false;
      };
      git.auto-local-branch = true;
      revsets.log = "..";
    };
  };
}
