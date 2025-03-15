{
  substituters = [
    "https://nix-community.cachix.org"
    "https://cache.nixos.org"
    "https://attic.aftix.xyz/cfg-actions"
  ];
  trusted-public-keys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "cfg-actions:R9aJEQdcJT8NrUh1yox2FgZfmzRrKi6MAobbfuRvv3g="
  ];
  extra-experimental-features = [
    "nix-command"
    "flakes"
    "pipe-operator"
  ];
}
