# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
let
  flake = import ../..;
  inherit (flake) lib inputs;
  pkgs = import inputs.nixpkgs {overlays = [lib.libpkgsOverlay];};
in {
  simple = pkgs.writeNushellApplication {
    name = "simple";
    text = "echo 1";
  };

  env = pkgs.writeNushellApplication {
    name = "env";
    runtimeEnv.FOO = "foo";
    text = "echo $env.FOO";
  };

  plugin = pkgs.writeNushellApplication {
    name = "plugin";
    nuPlugins = [flake.legacyPackages.${pkgs.hostPlatform.system}.nu_plugin_strutils];
    text = "'A…C' | str deunicode";
  };

  stdin = pkgs.writeNushellApplication {
    name = "stdin";
    text =
      /*
      nu
      */
      ''
        def main [] {
          echo $"stdin: ($in)"
        }
      '';
  };

  stdin-env = pkgs.writeNushellApplication {
    name = "stdin";
    runtimeEnv.FOO = "foo";
    text =
      /*
      nu
      */
      ''
        def main [] {
          echo $"foo: ($env.FOO) stdin: ($in)"
        }
      '';
  };
}
