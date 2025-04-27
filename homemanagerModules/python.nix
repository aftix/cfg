{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkDefault;
  inherit (config.xdg) configHome cacheHome dataHome;
in {
  home = {
    packages = with pkgs; [
      python3
      mypy
      python3Packages.flake8
      python3Packages.python-lsp-server
      python3Packages.pyls-flake8
      python3Packages.pylsp-mypy
      pipx
      micromamba
    ];

    sessionVariables = {
      PYTHONSTARTUP = mkDefault "${configHome}/python/pythonrc";
      PYTHONPYCACHEPREFIX = mkDefault "${cacheHome}/python";
      PYTHONUSERBASE = mkDefault "${dataHome}/python";
    };
  };

  my.shell = {
    upgradeCommands = ["pipx upgrade-all"];
    neededDirs = with config.home.sessionVariables; [
      PYTHONPYCACHEPREFIX
      PYTHONUSERBASE
    ];
  };

  xdg.configFile."python/pythonrc".text =
    /*
    python
    */
    ''
      def is_vanilla() -> bool:
        import sys
        return not hasattr(__builtins__, '__IPYTHON__') and 'bpython' not in sys.argv[0]

      def setup_history():
        import os
        import atexit
        import readline
        from pathlib import Path

        if state_home := os.environ.get('XDG_STATE_HOME'):
            state_home = Path(state_home)
        else:
            state_home = Path.home() / '.local' / 'state'

        history: Path = state_home / 'python_history'

        readline.read_history_file(str(history))
        atexit.register(readline.write_history_file, str(history))

      if is_vanilla():
        setup_history()
    '';
}
