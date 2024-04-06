{ ... }:

let
  channels = import ./channels.nix { config = { }; stableconfig = { }; };
in
with channels;
{
  imports = [ 
    ./impermanence/nixos.nix
  ];

  # Save network manager connections between boots
  environment.persistence."/persist".directories = [
    "/etc/NetworkManager/system-connections"
  ];

  networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];
  services.resolved = {
    enable = true;
    dnssec = "true";
    domains = [ "~." ];
    fallbackDns = [ "1.1.1.1" "1.0.0.1" ];
    dnsovertls = "true";
  };
    
  environment.systemPackages = with pkgs; [
    networkmanager-openvpn
  ];
}
