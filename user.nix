{lib, ...}: let
  channels = import ./channels.nix {
    config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "discord"
        "vault"
      ];
    stableconfig = {};
  };
in
  with channels; {
    imports = [
    ];

    programs.ssh.startAgent = true;
    services.udisks2.enable = true;

    environment.systemPackages = with pkgs; [
      ssh-agents
      pinentry-curses
      pinentry-gtk2
      elvish
      carapace
      home-manager
      udisks
      udiskie
    ];

    users.users.aftix = {
      isNormalUser = true;
      description = "aftix";
      extraGroups = ["networkmanager" "wheel"];
      shell = pkgs.zsh;
      uid = 1000;
      hashedPasswordFile = "/state/passwd.aftix";
      packages = with pkgs; [
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
