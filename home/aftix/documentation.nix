{
  lib,
  mylib,
  config,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv) mkDerivation;
  inherit (lib.strings) escapeShellArg;
  titlePrefix = config.mydocs.prefix;
  renderedDocs = builtins.mapAttrs mylib.docs.manPage config.mydocs.pages;
in
  mkDerivation {
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
          if config.mydocs.enable
          then "echo ${escapeShellArg (mylib.docs.manPage "${titlePrefix}" {
            _docsName = "Hamilton \\- Configuration documentation for my NixOS install";
            _docsSeeAlso = lib.mapAttrsToList (title: _: "${titlePrefix}-${title}(7)") config.mydocs.pages;
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
  }
