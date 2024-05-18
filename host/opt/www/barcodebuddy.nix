{
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf mkDefault;
  cfg = config.my.www;
in {
  options.my.www.barcodebuddySubdomain = lib.options.mkOption {
    default = "bbuddy";
    type = lib.types.str;
  };

  config = mkIf config.services.barcodebuddy.enable {
    services.barcodebuddy = {
      inherit (cfg) user group;
      hostName = mkDefault "${cfg.barcodebuddySubdomain}.${cfg.hostname}";
      acmeHost = mkDefault cfg.hostname;
    };
  };
}
