{upkgs, ...}: {
  environment.systemPackages = [
    upkgs.home-manager
  ];

  users.users.aftix = {
    isNormalUser = true;
    hashedPasswordFile = "/state/passwd.aftix";
    description = "aftix";
    extraGroups = [
      "networkmanager"
      "wheel"
      "scanner"
      "lp"
      "dialout"
    ];

    shell = upkgs.zsh;

    uid = 1000;
    subUidRanges = [
      {
        count = 65536;
        startUid = 231072;
      }
    ];
    subGidRanges = [
      {
        count = 65536;
        startGid = 231072;
      }
    ];
  };
}
