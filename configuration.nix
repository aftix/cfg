{
  upkgs,
  spkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./machine.nix
    ./user.nix
    ./vpn.nix
  ];

  nix = {
    nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "nixos-config=/home/aftix/src/cfg/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
    settings.experimental-features = ["nix-command" "flakes"];
    gc = {
      automatic = true;
      persistent = true;
      dates = "daily";
      options = "--delete-older-than 30d";
    };
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot = {
      enable = true;
      consoleMode = "auto";
      editor = false;
      memtest86.enable = true;
    };
  };

  # Opt-in to state

  environment = {
    persistence = {
      # /persist is backed up (btrfs subvolume under safe/)
      "/persist" = {
        hideMounts = true;
        directories = ["/var/lib/nixos" "/etc/NetworkManager/system-connections"];
      };
      # /state is not backup up (btrfs subvolume under local)
      "/state" = {
        hideMounts = true;
        directories = ["/var/log" "/var/lib/bluetooth" "/var/lib/systemd/coredump"];
      };
    };

    systemPackages = with upkgs; [
      spkgs.systemd
      spkgs.dbus
      spkgs.sudo
      fuse
      pipewire
      wireplumber
      curl
      btrfs-progs
      inotify-tools
      openssh
      rsync
      gnupg
      python3
      zsh
      git
      jujutsu
      libsForQt5.kwin
      kdePackages.sddm
      catppuccin-sddm-corners
      hyprland
      hyprlock
      hypridle
      hyprpaper
      hyprcursor
      xdg-desktop-portal-hyprland
      hyprland-protocols
      helix
      eza
      dust
      bat
      ripgrep
      fzf
      ffmpeg_5
      mpv
      yt-dlp
      imagemagick
      starship
      wl-clipboard
      xclip
      clipman
    ];
  };

  fonts.packages = with upkgs; [
    inconsolata
    dejavu_fonts
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    dina-font
    proggyfonts
    nerdfonts
  ];

  # Users
  security.sudo = {
    enable = true;
    execWheelOnly = true;
  };

  users = {
    mutableUsers = false;
    users.root.hashedPasswordFile = "/state/passwd.root";
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11"; # Did you read the comment?
}
