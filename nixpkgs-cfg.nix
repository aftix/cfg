{
  inputs ? import ./inputs.nix,
  myLib ? import ./lib.nix {inherit inputs;},
  overlay ? import ./overlay.nix {inherit inputs myLib;},
  ...
}: {
  nixpkgs = {
    overlays = [
      inputs.nur.overlays.default
      inputs.attic.overlays.default
      inputs.lix-module.overlays.default
      myLib.libpkgsOverlay
      overlay
    ];
    config = {
      allowUnfreePredicate = pkg:
        builtins.elem (inputs.nixpkgs.lib.getName pkg) [
          "discord"
          "pay-by-privacy"
          "aspell-dict-en-science"
        ];

      permittedInsecurePackages = [
        "jitsi-meet-1.0.8043"
      ];
    };
  };
}
