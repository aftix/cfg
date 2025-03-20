lib: self: {
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
  registerMimes = applications: lib.mergeAttrsList (map self.generateMimes applications);

  # builtins.toString except stringify bools as "true"/"false" instead of "1"/"0"
  stringify = x:
    if builtins.isBool x
    then
      if x
      then "true"
      else "false"
    else builtins.toString x;
}
