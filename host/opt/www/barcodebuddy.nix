{
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf mkDefault mkForce;
  cfg = config.my.www;
in {
  options.my.www.barcodebuddySubdomain = lib.options.mkOption {
    default = "bbuddy";
    type = lib.types.str;
  };

  config = mkIf config.services.barcodebuddy.enable {
    services = {
      barcodebuddy = {
        inherit (cfg) user group;
        hostName = mkDefault "${cfg.barcodebuddySubdomain}.${cfg.hostname}";
        acmeHost = mkDefault cfg.hostname;
      };

      nginx.virtualHosts."${config.services.barcodebuddy.hostName}".extraConfig = mkForce ''
        index index.php index.html index.htm;
        client_max_body_size 20M;
        client_body_buffer_size 128k;
        include /etc/nginx/bots.d/blockbots.conf;
        include /etc/nginx/bots.d/ddos.conf;
      '';
    };
  };
}
