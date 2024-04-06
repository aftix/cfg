{upkgs, ...}: {
  programs.ssh.startAgent = true;

  environment.systemPackages = with upkgs; [
    ssh-agents
    pinentry-curses
    pinentry-gtk2
    elvish
    carapace
    home-manager
    udisks
    udiskie
  ];
  services.udisks2.enable = true;

  users.users.aftix = {
    isNormalUser = true;
    description = "aftix";
    extraGroups = ["networkmanager" "wheel"];
    shell = upkgs.zsh;
    uid = 1000;
    hashedPasswordFile = "/state/passwd.aftix";
    packages = with upkgs; [
      rustup
      go
      sccache
      firefox-bin
      ungoogled-chromium
      pipx
      conda
      pavucontrol
      mpc-cli
      pass
      xdotool
      vault
      gh
      element-desktop
      discord
      betterdiscordctl
      tofi
      slurp
      libnotify
      notify-desktop
      weechat-unwrapped
      weechatScripts.weechat-notify-send
      python312Packages.aria2p
    ];
  };
}
