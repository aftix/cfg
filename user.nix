{upkgs, ...}: {
  environment.systemPackages = with upkgs; [
    elvish
    carapace
    home-manager
  ];

  users.users.aftix = {
    isNormalUser = true;
    description = "aftix";
    extraGroups = ["networkmanager" "wheel" "scanner" "lp"];
    shell = upkgs.zsh;
    uid = 1000;
    hashedPasswordFile = "/state/passwd.aftix";
    packages = with upkgs; [
      elvish
      carapace
      home-manager
    ];
  };
}
