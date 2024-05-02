{
  lib,
  config,
}: let
  inherit (lib.strings) toUpper;
  cfg = config.my.docs;
in rec {
  tagged = {
    tag,
    content,
    ...
  }: ".TP\n\\fB${tag}\\fP\n${content}";
  mergeTagged = lst: builtins.concatStringsSep "\n" (map tagged lst);
  mergeTaggedAttrs = attrs: mergeTagged (lib.mapAttrsToList (name: value: value) attrs);

  URI = uri: ".UR ${uri}\n.UE\n";
  mailto = address: ".MT ${mailto}\n.ME\n";

  # For references to other man pages
  manURI = {
    name,
    mansection ? 7,
  }: ".MR ${name} ${builtins.toString mansection}";
  mergeManURIs = lst: builtins.concatStringsSep "\n" (map manURI lst);

  pageTitle = name: let
    title =
      if cfg.prefix == name
      then name
      else "${cfg.prefix}-${name}";
  in ".TH \"${toUpper title}\" 7 \"{{date}}\"";

  section = title: content: ".SH ${title}\n${content}";
  subsection = title: content: ".SS ${title}\n${content}";
  mergeSubsections = attrs: builtins.concatStringsSep "\n" (lib.mapAttrsToList (name: value: subsection name value) attrs);
  paragraph = text: ".PP\n" + text;

  example = caption: content: ''
    Example: ${caption}
    .EX
    .RS 8
    ${content}
    .RE
    .EE
  '';

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
        (section "SEE ALSO" (
          mergeManURIs
          (
            if title != cfg.prefix
            then _docsSeeAlso ++ [{name = cfg.prefix;}]
            else _docsSeeAlso
          )
        ))
      ]);
}
