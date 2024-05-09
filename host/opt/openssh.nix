{
  lib,
  config,
  ...
}: let
  inherit (lib.options) mkOption;
  cfg = config.my.authorized_keys;
in {
  options.my.authorized_keys = mkOption {
    default = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAKGwAhIYy+i9+9cJJUvQKLxxaBFZLMflqKU/5L+uiRs aftix@aftix.xyz"
    ];
  };

  config = {
    users.users.aftix = lib.mkIf config.my.users.aftix.enable {
      openssh.authorizedKeys.keys = cfg;
    };

    networking.firewall.allowedTCPPorts = [22];

    services = {
      fail2ban.enable = true;

      openssh = {
        enable = true;

        listenAddresses = [
          {
            addr = "0.0.0.0";
            port = 22;
          }
        ];

        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = false;
        };

        extraConfig = ''
          ClientAliveInterval 900
          ClientAliveCountMax 0
          IgnoreRhosts yes
          HostbasedAuthentication no
          Subsystem sftp  /usr/lib/ssh/sftp-server -f AUTHPRIV -l INFO
        '';
      };
    };
  };
}
