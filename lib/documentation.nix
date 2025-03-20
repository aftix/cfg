lib: self: let
  inherit
    (lib)
    concatMapStringsSep
    mapAttrsToList
    toUpper
    optionalString
    optional
    ;
in {
  tagged = {
    tag,
    content,
    ...
  }: ".TP\n\\fB${tag}\\fP\n${content}";

  mergeTagged = concatMapStringsSep "\n" self.tagged;

  mergeTaggedAttrs = attrs: self.mergeTagged (mapAttrsToList (_: value: value) attrs);

  URI = uri: ".UR ${uri}\n.UE\n";
  mailto = address: ".MT ${address}\n.ME\n";

  # For references to other man pages
  manURI = {
    name,
    mansection ? 7,
  }: ".MR ${name} ${builtins.toString mansection}";
  mergeManURIs = concatMapStringsSep "\n" self.manURI;

  pageTitle = prefix: name: let
    title =
      if prefix == name
      then name
      else "${prefix}-${name}";
  in ".TH \"${toUpper title}\" 7 \"{{date}}\"";

  section = title: content: ".SH ${title}\n${content}";
  subsection = title: content: ".SS ${title}\n${content}";
  mergeSubsections = attrs: builtins.concatStringsSep "\n" (mapAttrsToList self.subsection attrs);
  paragraph = text: ".PP\n" + text;

  example = caption: content: ''
    Example: ${caption}
    .EX
    .RS 8
    ${content}
    .RE
    .EE
  '';

  manPage = prefix: title: {
    _docsName,
    _docsSynopsis ? "",
    _docsExtraSections ? {},
    _docsExamples ? "",
    _docsSeeAlso ? [],
    ...
  }:
    builtins.concatStringsSep "\n" ([
        (self.pageTitle prefix title)
        (self.section "NAME" _docsName)
        (
          optionalString (_docsSynopsis != "")
          (self.section "SYNOPSIS" _docsSynopsis)
        )
        (
          optionalString (_docsExamples != "")
          (self.section "SYNOPSIS" _docsExamples)
        )
      ]
      ++ (mapAttrsToList self.section _docsExtraSections)
      ++ [
        (self.section "SEE ALSO" (
          self.mergeManURIs
          (
            _docsSeeAlso ++ optional (title != prefix) {name = prefix;}
          )
        ))
      ]);
}
