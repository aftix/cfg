# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
lib: self: let
  inherit
    (lib)
    optionalString
    concatMapStringsSep
    ;
in {
  toHyprMonitors = builtins.map (
    {
      desc ? "",
      mode ? "preferred",
      position ? "auto",
      scale ? "1",
      transform ? "",
    }: let
      description =
        optionalString (desc != "") "desc:" + desc;
      orientation =
        optionalString (transform != "")
        ",transform,"
        + transform;
    in "${description},${mode},${position},${scale}${orientation}"
  );

  toHyprWorkspaces = builtins.map ({
    name,
    options,
  }:
    builtins.concatStringsSep "," ([name] ++ options));

  toHyprCfg = let
    inherit (self) stringify;
    toCfgInner = tabstop: v:
      lib.foldlAttrs (
        acc: name: value:
          if builtins.isAttrs value
          then ''
            ${acc}${tabstop}${name} {${toCfgInner "${tabstop}  " value}
            ${tabstop}}
          ''
          else if builtins.isList value
          then
            acc
            + (
              concatMapStringsSep "" (
                elem: (toCfgInner tabstop {"${name}" = elem;})
              )
              value
            )
          else ''
            ${acc}
            ${tabstop}${name} = ${stringify value}''
      ) ""
      v;
  in
    toCfgInner "";
}
