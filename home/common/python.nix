{
  upkgs,
  lib,
  config,
  ...
}: {
  home = {
    packages = with upkgs; [
      python3
      mypy
      python311Packages.flake8
      python311Packages.python-lsp-server
      python311Packages.pyls-flake8
      python311Packages.pylsp-mypy
      pipx
      micromamba
    ];

    sessionVariables.PYTHONSTARTUP = lib.mkDefault "${config.home.homeDirectory}/.config/python/pythonrc";
  };

  xdg.configFile."python/pythonrc".text = ''
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
