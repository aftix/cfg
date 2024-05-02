_: {
  # Configuration for my specific displays
  wayland.windowManager.hyprland.settings = {
    monitor = [
      "desc:ASUSTek COMPUTER INC ASUS VG27W 0x0001995C,preferred,0x0,1"
      # transform 1 is 90 degree rotation cw
      "desc:ViewSonic Corporation VX2703 SERIES T8G132800478,preferred,2560x-180,1,transform,1"
      ",preferred,auto,1"
    ];

    workspace = [
      "1, persistent:true, monitor:desc:ASUSTek COMPUTER INC ASUS VG27W 0x0001995C, default:true"
      "2, persistent:true, monitor:desc:ViewSonic Corporation VX2703 SERIES T8G132800478, default:true"
      "2, layoutopt:orientation:top"
    ];
  };
}
