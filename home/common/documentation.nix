{
  upkgs,
  lib,
  mylib,
  config,
  ...
}: let
  cfg = config.my.docs;

  builder = let
    inherit (lib.strings) escapeShellArg;
    titlePrefix = cfg.prefix;
    renderedDocs = builtins.mapAttrs mylib.manPage cfg.pages;
  in
    upkgs.stdenv.mkDerivation {
      pname = "aftix-docs";
      version = "0.0.1";

      meta = with lib; {
        description = "Automatically generated documentation for my NixOS setup";
        homepage = "https://github.com/aftix/cfg";
        license = licenses.mit;
        maintainers = [
          {
            name = "Wyatt Campbell";
            email = "aftix@aftix.xyz";
            github = "aftix";
            githubId = "4008299";
            matrix = "@aftix:matrix.org";
            keys = [{fingerprint = "577F 1276 A95A 4AF2 E452 167F 706F 0A8F 1ACD DF68";}];
          }
        ];
      };

      dontUnpack = true;
      dontBuild = true;

      installPhase = builtins.concatStringsSep "\n" ([
          "mkdir -p \"$out/share/man/man7\""
        ]
        ++ (lib.mapAttrsToList (title: docs: "echo ${escapeShellArg docs} > \"${titlePrefix}-${title}.man\"") renderedDocs)
        ++ [
          (
            if cfg.enable
            then "echo ${escapeShellArg (mylib.manPage "${titlePrefix}" {
              _docsName = "${titlePrefix} \\- Configuration documentation for my NixOS install";
              _docsSeeAlso = lib.mapAttrsToList (title: _: {name = "${titlePrefix}-${title}";}) cfg.pages;
            })} > \"${titlePrefix}.man\""
            else ""
          )
        ]
        ++ [
          ''
            DATE="$(date +%Y-%m-%d)"
            for f in "${titlePrefix}-"*.man; do
              [[ -z "$f" ]] && break
              [[ "$f" == "${titlePrefix}-*.man" ]] && break
              FILE="$(basename "$f")"
              sed "s/{{date}}/$DATE/g" < "$f" > "$out/share/man/man7/''${FILE%.man}.7"
            done
            if [[ -f "${titlePrefix}.man" ]]; then
              sed "s/{{date}}/$DATE/g" < "${titlePrefix}.man" > "$out/share/man/man7/${titlePrefix}.7"
            fi
          ''
        ]);
    };
in {
  options = {
    my.docs = let
      inherit (lib.options) mkOption mkEnableOption;
    in {
      pages = mkOption {
        default = {};
        description = ''
          Documentation to generate for the configuration.
          Consists of an attribute set where each key is the name of the documentation

          The name of each attribute is the name of the corresponding documentation page,
          rendered as "<prefix>-<_docsName>"

          A page is an attribute set with the following required attributes:

          * _docsTitle - The "NAME" section of the man page

          There are also the following optional attributes:

          * _docsSynopsis - The synopsis of the command
          * _docsExamples - A "\\n" delimited string of examples for the "Examples" section
          * _docsSeeAlso - a list of man pages to list verbatim in the "See Also" section
          * _docsExtraSections - An attribute set where each attribute is another section
              to add to the man page, to be inserted between "Options" and "Exit Status"

          The ordering of sections are: Name, Synopsis, Description, Examples, Overview, Defaults,
          Options, [_docsExtraSections...], Exit Status, Environment, Files, Standards, See Also,
          History, Bugs

          Section text is rendered with `groff`

          Attributes other than those starting with _docs are ignored
        '';
      };
      prefix = mkOption {
        default = "nixos";
        description = "Prefix to prepend to documentation page names.";
      };
      version = mkOption {
        default = "0.0.1";
        description = "Version number of documentation";
        readOnly = true;
      };
      enable = mkEnableOption "my.docs";
    };
  };

  config.home.packages = lib.mkIf cfg.enable [builder];
}
