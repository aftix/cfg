# A version of pkgs.writeShellApplication that uses nushell instead of bash
# A lot is taken from https://github.com/hsjobeki/nixpkgs/tree/migrate-doc-comments/pkgs/build-support/trivial-builders/default.nix#L198:C5
# MIT Licensed
pkgs: {
  # The name of the script to write.
  name,
  # The script's text, not including a shebang.
  text,
  # The nushell derivation to use to run the script.
  nu ? pkgs.nushell,
  # Inputs to add to the script's `$PATH` at runtime.
  runtimeInputs ? [],
  # Plugins to add to the shell, must be the path to the executable
  # or a derivation where lib.getExe correctly gets the executable
  nuPlugins ? [],
  # Extra environment variables to set at runtime.
  runtimeEnv ? null,
  # stdenv.mkDerivation's `meta` argument.
  meta ? {},
  # stdenv.mkDerivation's `passthru` argument.
  passthru ? {},
  /*
  The `checkPhase` to run. Defaults to nu-check (a nushell built-in)
  The script path will be given as `$target` in the `checkPhase`.
  */
  checkPhase ? null,
  # Extra arguments to pass to stdenv.mkDerivation.
  derivationArgs ? {},
  # Whether to inherit the current `$PATH` in the script.
  inheritPath ? true,
}: let
  inherit (pkgs) lib;

  inherit (lib) optionalString;

  getNuPlugin = plugin:
    if lib.isString plugin
    then plugin
    else if lib.isDerivation plugin
    then lib.getExe plugin
    else throw "writeNushellApplication: invalid type given for nuPlugins";

  sourceEnvJSON = pkgs.writeTextFile {
    inherit meta passthru;
    name = "${name}-env.json";
    allowSubstitutes = true;
    preferLocalBuild = false;
    text = builtins.toJSON runtimeEnv;
  };
in
  pkgs.writeTextFile {
    inherit name meta passthru derivationArgs;
    executable = true;
    destination = "/bin/${name}";
    allowSubstitutes = true;
    preferLocalBuild = false;
    text =
      /*
      nu
      */
      ''
        #!${lib.getExe nu} --stdin ${lib.optionalString (nuPlugins != []) "--plugins [${lib.concatStringsSep "," (builtins.map getNuPlugin nuPlugins)}]"}
        ${optionalString (runtimeEnv != null) "open ${sourceEnvJSON} | load-env"}

        # Setup the PATH environmental variable
        $env.PATH = ($env.PATH | split row (char esep))
        ${optionalString (runtimeInputs != [])
          /*
          nu
          */
          ''
            $env.PATH = ("${lib.makeBinPath runtimeInputs}" | ${optionalString inheritPath "append $env.PATH |"} split row (char esep))
          ''}

        ${text}
      '';

    checkPhase = let
    in
      if checkPhase == null
      then
        /*
        bash
        */
        ''
          runHook preCheck
          ${lib.getExe nu} --commands "'$out/bin/${name}' | nu-check --debug"
          runHook postCheck
        ''
      else checkPhase;
  }
