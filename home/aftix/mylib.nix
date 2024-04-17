# Personal code library
# Import separately from `imports = [ ... ]` and use `_module.args.mylib = ...`
# to use it in imported modules.
{
  lib,
  config,
  ...
}: rec {
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
  registerMimes = applications: lib.mergeAttrsList (map generateMimes applications);

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
              builtins.concatStringsSep "\n" ([acc]
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

  # Functions for building man pages

  docs = let
    inherit (lib.strings) toUpper;
  in rec {
    tagged = {
      tag,
      content,
      ...
    }: ".TP\n\\fB${tag}\\fP\n${content}";
    mergeTagged = lst: builtins.concatStringsSep "\n" (map tagged lst);
    mergeTaggedAttrs = attrs: mergeTagged (lib.mapAttrsToList (name: value: value) attrs);

    pageTitle = name: let
      title =
        if config.mydocs.prefix == name
        then name
        else "${config.mydocs.prefix}-${name}";
    in ".TH \"${toUpper title}\" 7 \"{{date}}\"";
    section = title: content: ".SH ${title}\n${content}";

    manPage = title: {
      _docsName,
      _docsSynopsis ? "",
      _docsExtraSections ? {},
      _docsExamples ? "",
      _docsSeeAlso ? [],
      ...
    }:
      builtins.concatStringsSep "\n" ([
          (pageTitle title)
          (section "NAME" _docsName)
          (
            if _docsSynopsis != ""
            then section "SYNOPSIS" _docsSynopsis
            else ""
          )
          (
            if _docsExamples != ""
            then section "SYNOPSIS" _docsExamples
            else ""
          )
        ]
        ++ (lib.mapAttrsToList (title: content: section title content) _docsExtraSections)
        ++ [
          (
            if _docsSeeAlso != []
            then section "SEE ALSO" (builtins.concatStringsSep ", " _docsSeeAlso)
            else ""
          )
        ]);
  };
}
