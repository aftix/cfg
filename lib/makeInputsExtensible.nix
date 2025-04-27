# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
lib: let
  makeInputsExtensible =
    # Based off of lib.makeExtensibleWithCustomname
    # from https://github.com/NixOS/nixpkgs/blob/2ba42c60e00e2fb01dac1917439c55e199661f8c/lib/fixed-points.nix#L444:C3
    # MIT Licensed
    # Allows the inputs to be overriden by downstream code
    rattrs:
      lib.fix' (
        self: (rattrs self) // {overrideInputs = f: makeInputsExtensible (lib.extends (lib.toExtension f) rattrs);}
      );
in
  makeInputsExtensible
