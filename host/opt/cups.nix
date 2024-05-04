{pkgs, ...}: {
  services = {
    printing.enable = true;
    avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = true;
      openFirewall = true;
    };
  };

  hardware.sane = {
    enable = true;
    extraBackends = with pkgs; [sane-airscan];
  };
}
