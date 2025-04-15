{inputs ? (import ./.).inputs, ...}: {
  nixpkgs = {
    overlays = [
      inputs.nur.overlays.default
      inputs.attic.overlays.default
      inputs.lix-module.overlays.default
      inputs.self.lib.libpkgsOverlay
      inputs.self.overlays.default
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
