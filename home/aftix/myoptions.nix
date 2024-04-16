{lib, ...}: let
  inherit (lib.options) mkOption mkEnableOption;
in {
  ###### Configuration options
  options.mydocs = {
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
    enable = mkEnableOption "mydocs";
  };
}
