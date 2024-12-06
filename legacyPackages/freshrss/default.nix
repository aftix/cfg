{
  lib,
  newScope,
}:
lib.makeScope newScope (self: let
  inherit (self) callPackage;
in {
  official = callPackage ./official.nix {};
  cntools = callPackage ./cntools.nix {};
  latex = callPackage ./latex.nix {};
  reddit = callPackage ./reddit.nix {};
  autottl = callPackage ./autottl.nix {};
  links = callPackage ./links.nix {};
  ezpriorities = callPackage ./ezpriorities.nix {};
  ezread = callPackage ./ezread.nix {};
  threepane = callPackage ./threepane.nix {};
})
