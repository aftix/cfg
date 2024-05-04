{
  lib,
  config,
  ...
}: {
  options.my.lib = lib.options.mkOption {
    default = {};
  };

  config.my.lib = rec {
    # Generate an attribute set of mimetypes usable by xdg.mimeApps
    # Input is an attribute which maps an application to a
    # list of mimetypes. The attribute sets need the attribute "application",
    # which is the application name (without the .desktop extension) and
    # the attribute "mimetypes" which is a list of mimetype strings
    generateMimes = {
      application,
      mimetypes,
    }:
      lib.mergeAttrsList (map (type: {"${type}" = ["${application}.desktop"];}) mimetypes);

    # Map generateMimes on a list of attribute sets and merge into one attribute set
    registerMimes =
      if config.my.registerMimes
      then (applications: lib.mergeAttrsList (map generateMimes applications))
      else (_: {});

    # builtins.toString except stringify bools as "true"/"false" instead of "1"/"0"
    stringify = x:
      if builtins.isBool x
      then
        if x
        then "true"
        else "false"
      else builtins.toString x;

    toHyprCfg = let
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
              (
                builtins.concatStringsSep "" ([acc]
                  ++ (map (
                      elem: (toCfgInner tabstop {"${name}" = elem;})
                    )
                    value))
              )
            else ''
              ${acc}
              ${tabstop}${name} = ${stringify value}''
        ) ""
        v;
    in
      toCfgInner "";
  };
}
